%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
%  Updated: 20260420 - Alexander Gehrke
%
%#ok<*GVMIS>
%#ok<*UNRCH>

clear
clear global lastSeedingTime recIdx optResults

% Keep mutable states global so bayesopt iterations can update them
global lastSeedingTime
global recIdx
global optResults

optResults = [];
recIdx = 1;

%% Configure experiment and write config file
root_dir = "C:\PIV_SANDBOX\20260424_ATG_highFreq_opt_5\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
camera_exe = "C:\Users\agehrke\Downloads\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";

davis_project_source = "C:\PIV_SANDBOX\davis_project_source_lisbon\";

% Experimental PIV parameters
eset = struct( ...
    'acquisition_freq_Hz', 53, ...
    'delta_t_us', 180, ...
    'pulse_width_us', 5, ...
    'nDoubleFrames', 410, ... 
    'ext_trigger', false ...
);

% Communication parameters
cset = struct( ...
    'bnc_connection', "COM7", ...
    'laser_connection', "COM9", ...
    'valveArduino_connection', 3, ...
    'camOne_connection', "192.168.3.10", ...
    'camTwo_connection', "192.168.1.10" ...
);

% Evaluation parameters
evset = struct( ...
    'targetTI', 0.15, ...
    'doPlot', true, ...
    'wTI', 0.0599, ...                
    'wH1', 0.0026, ...
    'wH2', 0.0100, ...
    'wH3', 0.5030, ...
    'wA', 0.4245, ...
    'relCut', 0.05 ...
);

% Optimization parameters
oset = struct( ...
    'alphaRange', [0, 59.5], ...
    'relBetaRange', [0, 1], ...
    'theta_min', 30, ...
    'skipCycles', 5, ...
    'plotting', true ...
);

% Create parameter file:
configFile = write_experiment_config(root_dir, eset, cset, evset, oset, davis_exe, davis_project_source, ...
    "verbose", true, ...
    "davis_proj_name", "optimusPivLisbon", ... 
    "camera_index", 1, ...                 
    "davis_lvs_name", "twoDimGPU_400");


%% Read config (for confirmation)
config = read_experiment_config(configFile, false);

create_folder_structure(config);
initRecordingLog(config.log_path);

% --- Initialize Command Window Logging ---
diaryFile = fullfile(root_dir, 'optimization_log.txt');
diary(diaryFile);
disp("--- Starting Optimization Run ---");
disp("Date/Time: " + string(datetime('now')));


%% Setup Equipment
disp(" ");

bnc = bnc_init(config.COM_settings.bnc_connection);
bnc_program(bnc, config.PIV_settings.acquisition_freq_Hz, config.PIV_settings.delta_t_us, config.PIV_settings.pulse_width_us, config.PIV_settings.nDoubleFrames);

Audio = audioplayer([sin(1:.6:400), sin(1:.7:400), sin(1:.4:400)], 22050); 
disp(' ')
disp('CONNECTION TO LASER WILL BE INITIALIZED')
disp('FULL LASER SAFETY REQUIRED TO CONTINUE')
disp('!!! DOORS CLOSED - GOGGLES ON - NO JEWELRY ON ARMS AND HANDS !!!')
disp('WHEN YOU CONTINUE THE LASER WILL BE ARMED TO FULL POWER AND START TO FIRE AS EXPERIMENTS ARE BEING CONDUCTED. USE EXTREME CAUTION!')
disp(' ')
play(Audio);
response = input('HAVE YOU FOLLOWED ALL THE LASER SAFETY CHECKLIST AND ARE READY TO CONTINUE? (YES/NO): ', 's');
disp('')

if strcmpi(response, 'YES')
    disp('LASER COMING ONLINE IN')
    disp('3'); play(Audio); pause(1);
    disp('2'); play(Audio); pause(1);
    disp('1'); play(Audio); pause(1);

    laserControl = DM40Control(config.COM_settings.laser_connection); 
    laserDashboard = LaserDashboard(laserControl); 
    laserControl.Verbose = false; 
    targetHeads = 'both'; 
    
    laserControl.setPRFSource(1, targetHeads); % External frequency control
    laserControl.setGateSource(1, targetHeads); % External gate control
    laserControl.setFPK(0, 'both'); % No 'First-pulse-kill'

    disp('LASER CONNECTION ESTABLISHED - LASER CAN FIRE AT ANY MOMENT WITHOUT WARNING')
else
    error('LASER CONNECTION ABORTED BY USER.');
end

disp("--- LAUNCH CAMERA PROGRAM NOW ---")

disp("Connect to seeding solenoid valve, this will seed for 2 sec")
valveArduino = conSolenoidValve(config.COM_settings.valveArduino_connection);
pause(2) % Don't reduce this below 2sec, the Arduino can't handle it.
closeSolenoidValve(valveArduino);

% Bundle hardware handlers to pass smoothly through optimization
hw.bnc = bnc;
hw.laserControl = laserControl;
hw.valveArduino = valveArduino;

return


%% Set up optimization
vars = [
    % optimizableVariable('frequency', config.OPT_settings.freqencyRange)
    optimizableVariable('alpha', config.OPT_settings.alphaRange)
    optimizableVariable('relBeta', config.OPT_settings.relBetaRange)
];

lastSeedingTime = tic;

% Run Bayesian optimization passing hardware and config via anonymous function
results = bayesopt(@(x) atgOpt_objFcn_synchr(10, x.alpha, x.relBeta, config, hw), ...
    vars, ...
    'MaxObjectiveEvaluations', 50, ...
    'IsObjectiveDeterministic', false, ...
    'AcquisitionFunctionName', 'expected-improvement-plus');

best_J = results.MinObjective;
fprintf('Best opt val: %.6f\n', best_J);

% Disarm system, cleanup
bnc_disarm(hw.bnc)

delete(hw.bnc)
delete(laserDashboard)
delete(hw.laserControl)

% Safe data
save(fullfile(config.root_dir, "workspaceOptimization.mat"))
disp("Saved workspace matfile.")

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
diary off; % Stop command line logging
