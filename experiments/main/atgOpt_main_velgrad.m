%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
%  Updated 20251022
%#ok<*GVMIS>
clear
clear global bnc triggerDelay optPIV_settings recIdx optResults valveArduino
global bnc
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
% root_dir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250725_test\";
root_dir = "C:\PIV_SANDBOX\20251022_ATG_bayes_opt_4\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
camera_exe = "C:\Users\agehrke\Downloads\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";
% This needs to be the project containing the most recent calibration and
% LVS files and include a dummy/template case:
davis_project_source = "C:\PIV_SANDBOX\davis_project_source_dfd\"; 
configFile = fullfile(root_dir, "experiment_config.json");
% experimental PIV parameters
eset = struct( ...
    'acquisition_freq_Hz', 20, ...
    'delta_t_us', 180, ...
    'pulse_width_us', 5, ...
    'nDoubleFrames', 200, ...
    'ext_trigger', ext_trigger ...
);
% Communication parameters
cset = struct( ...
    'bnc_connection', "COM7", ...
    'laser_connection', "COM9", ...
    'camOne_connection', "192.168.3.10", ...
    'camTwo_connection', "192.168.1.10" ...
);
write_experiment_config(root_dir, eset, cset, davis_exe, davis_project_source, verbose);


%% Read config (for confirmation)
config = read_experiment_config(configFile, false);

root_dir = config.root_dir;
eset = config.PIV_settings;
cset = config.COM_settings;

create_folder_structure(config);
initRecordingLog(config.log_path);


%% Setup Equipment
disp(" ");
% Initialize BNC
bnc = bnc_init(cset.bnc_connection);
% Program BNC with current parameters
bnc_program(bnc, eset.acquisition_freq_Hz, eset.delta_t_us, eset.pulse_width_us, eset.nDoubleFrames);

% Initialize & arm cameras
% !!! For now launch through command line or using Visual Studio
% We need a communication protocol between c++ and Matlab -> TODO !!!
%
% camera_cmd = camera_exe + " " + configFile;
% status = system(camera_cmd)
disp("--- LAUNCH CAMERA PROGRAM NOW ---")

% Initialize particle seeding valve control
disp("Connect to seeding solenoid valve, this will seed for 2 sec")
valveArduino = conSolenoidValve(3);
pause(2)
closeSolenoidValve(valveArduino);


%% Set up optimization loop parameters
optPIV_settings.plotting = plotting;
optPIV_settings.config = config;
optPIV_settings.skipCycles = skipCycles;
optPIV_settings.theta_min = 30; % minimum grid closing angle [deg]

return


%% Set up optimization

% Define the optimization variables
vars = [
    optimizableVariable('frequency', [0.5, 6])
    optimizableVariable('alpha', [0, 59.5])
    optimizableVariable('relBeta', [0, 1])
    optimizableVariable('ampgrad', [-45 45])
    optimizableVariable('offsetgrad', [-45 45])
];

% Define the constraint function: must return <= 0 when satisfied
% constraintFcn = @(x) deal(x.beta - x.alpha, []);  % inequality c(x) <= 0 → ensures alpha > beta

lastSeedingTime = tic;

% Run Bayesian optimization
results = bayesopt(@(x) atgOpt_objFcn_velgrad(x.frequency, x.alpha, ...
    x.relBeta, x.ampgrad, x.offsetgrad), ...
    vars, ...
    'MaxObjectiveEvaluations', 100, ...
    'IsObjectiveDeterministic', false, ...
    'AcquisitionFunctionName', 'expected-improvement-plus');

% Run Bayesian optimization
% results = bayesopt(@(x) atgOpt_objFcn(x.frequency, x.alpha, x.beta), ...
%     vars, ...
%     'MaxObjectiveEvaluations', 60, ...
%     'IsObjectiveDeterministic', false, ...
%     'AcquisitionFunctionName', 'expected-improvement-plus', ...
%     'Constraints', constraintFcn);

best_frequency = results.XAtMinObjective.frequency;
% best_amplitude = results.XAtMinObjective.amplitude;
% best_offset = results.XAtMinObjective.offset;
best_J = results.MinObjective;

fprintf('Best frequency: %.4f\n', best_frequency);
% fprintf('Best amplitude: %.4f\n', best_amplitude);
% fprintf('Best offset: %.4f\n', best_offset);
fprintf('Best opt val: %.6f\n', best_J);

save(fullfile(root_dir, "workspaceOptimization.mat"))


%% Disarm system, cleanup
bnc_disarm(bnc)
% shutDownLaser(); % TODO: IMPLEMENT RS232 CONTROL
disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
