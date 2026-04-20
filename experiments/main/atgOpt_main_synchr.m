%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
%  Updated: 20260417 - Alexander Gehrke
%
%#ok<*GVMIS>
%#ok<*UNRCH>

clear
clear global bnc laserControl valveArduino triggerDelay optPIV_settings recIdx optResults
clear bnc laserControl

global bnc
global laserControl
global valveArduino
global lastSeedingTime
global optPIV_settings
global recIdx
global optResults

optResults = [];
recIdx = 1;

verbose = true;
ext_trigger = false;
plotting = true;
skipCycles = 5;


%% Configure experiment and write config file
root_dir = "C:\PIV_SANDBOX\20260417_ATG_highFreq_opt_1\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
camera_exe = "C:\Users\agehrke\Downloads\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";

% This needs to be the project containing the most recent calibration and
% LVS files and include a dummy/template case:
davis_project_source = "C:\PIV_SANDBOX\davis_project_source_lisbon\";

% Experimental PIV parameters
eset = struct( ...
    'acquisition_freq_Hz', 50, ...
    'delta_t_us', 180, ...
    'pulse_width_us', 5, ...
    'nDoubleFrames', 220, ... % Single frames: Double this number
    'ext_trigger', ext_trigger ...
);

% Communication parameters
cset = struct( ...
    'bnc_connection', "COM7", ...
    'laser_connection', "COM9", ...
    'valveArduino_connection', 3, ...
    'camOne_connection', "192.168.3.10", ...
    'camTwo_connection', "192.168.1.10" ...
);

% Create parameter file:
configFile = write_experiment_config(root_dir, eset, cset, davis_exe, davis_project_source, ...
    "verbose", verbose, ...
    "davis_proj_name", "optimusPivLisbon", ... 
    "camera_index", 1, ...                 
    "davis_lvs_name", "twoDimGPU_200");


%% Read config (for confirmation)
config = read_experiment_config(configFile, false);

root_dir = config.root_dir;
eset = config.PIV_settings;
cset = config.COM_settings;

create_folder_structure(config);
initRecordingLog(config.log_path);


%% Setup Equipment
disp(" ");

% Initialize BNC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bnc = bnc_init(cset.bnc_connection);
% Program BNC with current parameters
bnc_program(bnc, eset.acquisition_freq_Hz, eset.delta_t_us, eset.pulse_width_us, eset.nDoubleFrames);

% Initialize Laser %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Audio = audioplayer([sin(1:.6:400), sin(1:.7:400), sin(1:.4:400)], 22050); % Audio queue for laser boot up
disp(' ')
disp('CONNECTION TO LASER WILL BE INITIALIZED')
disp('FULL LASER SAFETY REQUIRED TO CONTINUE')
disp('!!! DOORS CLOSED - GOGGLES ON - NO JEWELRY ON ARMS AND HANDS !!!')
disp('WHEN YOU CONTINUE THE LASER WILL BE ARMED TO FULL POWER AND START TO FIRE AS EXPERIMENTS ARE BEING CONDUCTED. USE EXTREME CAUTION!')
disp(' ')
play(Audio);
response = input('HAVE YOU FOLLOWED ALL THE LASER SAFETY CHECKLIST AND ARE READY TO CONTINUE? (YES/NO): ', 's');
disp('')

% Use strcmpi for case-insensitive comparison
if strcmpi(response, 'YES')
    disp('LASER COMING ONLINE IN')
    disp('3')
    play(Audio); pause(1);
    disp('2')
    play(Audio); pause(1);
    disp('1')
    play(Audio); pause(1);

    laserControl = DM40Control(cset.laser_connection); % 1. Connect
    laserDashboard = LaserDashboard(laserControl); % 2. Open Dashboard
    laserControl.Verbose = false; % Decide what to display on command line
    targetHeads = 'both'; 
    
    % Set laser control parameters
    laserControl.setPRFSource(1, targetHeads);   % Set PRF to Internal (0) or external (1)
    laserControl.setGateSource(1, targetHeads);   % Set PRF to Internal (0) or external (1)

    disp('LASER CONNECTION ESTABLISHED - LASER CAN FIRE AT ANY MOMENT WITHOUT WARNING')
else
    error('LASER CONNECTION ABORTED BY USER.');
end


% Initialize & arm cameras %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% !!! For now launch through command line or using Visual Studio
% We need a communication protocol between c++ and Matlab -> TODO !!!
%
% camera_cmd = camera_exe + " " + configFile;
% status = system(camera_cmd)
disp("--- LAUNCH CAMERA PROGRAM NOW ---")

% Initialize particle seeding valve control %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp("Connect to seeding solenoid valve, this will seed for 2 sec")
valveArduino = conSolenoidValve(cset.valveArduino_connection);
pause(2)
closeSolenoidValve(valveArduino);


%% Set up optimization loop parameters
optPIV_settings.plotting = plotting;
optPIV_settings.config = config;
optPIV_settings.skipCycles = skipCycles;
optPIV_settings.theta_min = 30; % minimum grid closing angle [deg]

return


%% Set up optimization
% frequencyRange = [0.5, 8];
alphaRange = [0, 59.5];
relBetaRange = [0, 1];
% Define the optimization variables
vars = [
    % LISBON RUN PARAMETERS:
    % optimizableVariable('frequency', [7, 8])
    optimizableVariable('alpha', alphaRange)
    optimizableVariable('relBeta', relBetaRange)
    % DFD RUN PARAMETERS:
    % optimizableVariable('frequency', frequencyRange)
    % optimizableVariable('alpha', [0, 59.5])
    % optimizableVariable('relBeta', [0, 1])
];

% Define the constraint function: must return <= 0 when satisfied
% constraintFcn = @(x) deal(x.beta - x.alpha, []);  % inequality c(x) <= 0 → ensures alpha > beta

lastSeedingTime = tic;

% Run Bayesian optimization
% results = bayesopt(@(x) atgOpt_objFcn_synchr(x.frequency, x.alpha, x.relBeta), ...
results = bayesopt(@(x) atgOpt_objFcn_synchr(10, x.alpha, x.relBeta), ...
    vars, ...
    'MaxObjectiveEvaluations', 40, ...
    'IsObjectiveDeterministic', false, ...
    'AcquisitionFunctionName', 'expected-improvement-plus');

% Run Bayesian optimization
% results = bayesopt(@(x) atgOpt_objFcn(x.frequency, x.alpha, x.beta), ...
%     vars, ...
%     'MaxObjectiveEvaluations', 60, ...
%     'IsObjectiveDeterministic', false, ...
%     'AcquisitionFunctionName', 'expected-improvement-plus', ...
%     'Constraints', constraintFcn);

% best_frequency = results.XAtMinObjective.frequency;
% best_amplitude = results.XAtMinObjective.amplitude;
% best_offset = results.XAtMinObjective.offset;
best_J = results.MinObjective;

% fprintf('Best frequency: %.4f\n', best_frequency);
% fprintf('Best amplitude: %.4f\n', best_amplitude);
% fprintf('Best offset: %.4f\n', best_offset);
fprintf('Best opt val: %.6f\n', best_J);


%% Disarm system, cleanup
bnc_disarm(bnc)

delete(bnc)
delete(laserDashboard)
delete(laserControl)

clear bnc laserDashboard laserControl

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")


%% Safe data
save(fullfile(root_dir, "workspaceOptimization.mat"))

