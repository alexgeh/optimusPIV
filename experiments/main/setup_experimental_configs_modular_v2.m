%% Setting up parameters, data structure and initialize measurement equipment
%  Active-learning PIV loop, modular-control version
%  Version: 2026/04/29 - Alexander Gehrke / GPT-assisted modular upgrade
%
%  Notes:
%  - This file intentionally keeps active-learning settings close to the
%    experimental configuration, rather than hiding them in a separate
%    makeSettings helper.
%  - The actuation mode is NOT set manually. It is inferred later from the
%    active/provided design variables: if ampgrad or offsetgrad is active or
%    nonzero, the gradient ATG routine is used.

optResults = struct([]);
recIdx = 1;


%% Configure experiment and write config file
root_dir = "C:\PIV_SANDBOX\20260505_ATG_highFreq_actLearn_9\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
camera_exe = "C:\Users\agehrke\Downloads\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe"; %#ok<NASGU>

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
% These are used by objEval_turbulenceIntensity/turbulenceMetrics.
evset = struct( ...
    'targetTI', 0.20, ...
    'doPlot', true, ...
    'wTI', 0.0599, ...
    'wH1', 0.0026, ...
    'wH2', 0.0100, ...
    'wH3', 0.5030, ...
    'wA', 0.4245, ...
    'relCut', 0.05 ...
);

% Optimization / actuation parameters
% Keep all physical bounds here so they are written into the experiment
% config through write_experiment_config.
oset = struct( ...
    'freqRange', [0.5, 6], ...
    'fixedFreq', 6, ...
    'alphaRange', [0, 59.5], ...
    'relBetaRange', [0, 1], ...
    'ampgradRange', [-45, 45], ...
    'offsetgradRange', [-45, 45], ...
    'theta_min', 30, ...
    'skipCycles', 5, ...
    'seedInterval_min', 10, ...
    'plotting', true, ...
    ... % ATG controller settings used by runAtg_modular in gradient mode
    'AtgExe', "C:\Users\agehrke\Downloads\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe", ...
    'atgOutDir', "C:\Users\agehrke\Downloads\ATG_rec", ...
    'atgAllNodeIdx', 0:14, ...
    'atgMaxRpm', 1200, ...
    'atgMaxRpmPerS', 10000, ...
    'atgHomeRpm', 50, ...
    'atgHomeRpmPerS', 100, ...
    'atgControlRate_ms', 20, ...
    'atgShortCmdWait_s', 2, ...
    'atgLongCmdWait_s', 5, ...
    'atgTriggerDelay_s', 7, ...
    'atgPostTriggerMotion_s', 10 ...
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


%% Active-learning settings
% Main run settings. Keep these here or in the main script so the active
% learning run can be inspected in one place.
AL_settings = struct();
AL_settings.current_strategy = 'target';   % 'explore' or 'target'
AL_settings.n_iter = 50;
AL_settings.minSamplesForModel = 6;
AL_settings.plotWindow = 50;               % plot only new/current-run values
AL_settings.pauseBeforeLoop = true;
AL_settings.gp.kernelFunction = 'ardmatern52';

% Exploration acquisition settings.
% The GP uncertainty is combined equally across outputs after normalising by
% each output's training-data scale. The anti-clustering term is adaptive and
% only suppresses candidates that are too close to existing samples in the
% normalised input space. It is multiplicative, so it cannot turn a low-
% uncertainty point into a high-value exploration point.
AL_settings.explore = struct();
AL_settings.explore.antiCluster = struct();
AL_settings.explore.antiCluster.enabled = true;
AL_settings.explore.antiCluster.scaleFactor = 0.5;     % d0 = scaleFactor * median nearest-neighbour distance
AL_settings.explore.antiCluster.minScale = 0.02;       % normalised units; numerical guardrail
AL_settings.explore.antiCluster.maxScale = 0.25;       % normalised units; numerical guardrail
AL_settings.explore.antiCluster.fallbackScale = 0.10;  % used when there are too few samples

AL_settings.explore.globalUncertainty.enabled = true;
AL_settings.explore.globalUncertainty.nCandidates = 10000;
AL_settings.explore.globalUncertainty.seed = 1;

% Targeted-optimisation settings.
% The target objective is implemented in targetCost.m as a soft
% feasibility-first score:
%   1) match target outputs within user-defined tolerances;
%   2) heavily punish the part of the target error outside tolerance;
%   3) only then minimise lower-is-better penalty outputs such as CV/aniso.
%
% Tolerances are in physical output units. Relative tolerances work for
% nonzero targets, but zero targets need an explicit absolute tolerance.
AL_settings.targets = struct();
AL_settings.targets.TI_mean     = 0.20;
AL_settings.targets.dTIdy_slope = 0.00;
AL_settings.targets.dUdy_slope  = 3.00;

AL_settings.target = struct();
AL_settings.target.explorationBonus = 0.0;  % keep zero for first targeted tests
AL_settings.target.outsidePenalty   = 10;   % extra penalty outside tolerance
AL_settings.target.gateSharpness    = 10;   % penalty terms activate near targetScore <= 1
AL_settings.target.relTol           = 0.05; % fallback relative tolerance for nonzero targets

AL_settings.target.tol = struct();
AL_settings.target.tol.TI_mean     = 0.05 * abs(AL_settings.targets.TI_mean);
AL_settings.target.tol.dTIdy_slope = 0.02;
AL_settings.target.tol.dUdy_slope  = 0.30;  % absolute tolerance for zero target; tune for your scaling

% Penalty terms are normalised by the training-data output scale by default.
% This avoids mixing quantities with different magnitudes without introducing
% subjective weights. If needed later, explicit physical scales can be added:
%   AL_settings.target.penaltyScale.CV_U = 0.05;
%   AL_settings.target.penaltyScale.CV_TI = 0.10;
%   AL_settings.target.penaltyScale.aniso_mean = 0.05;
AL_settings.target.penaltyScale = struct();

% Choose active design-space variables here. The actuation mode is inferred:
% - no ampgrad/offsetgrad active and both zero -> synchronous actuation
% - ampgrad or offsetgrad active/nonzero       -> gradient actuation
%
% Current safe synchronous case:
% AL_settings.active_input_names = {'alpha','relBeta'};
%
% Extended gradient-control case:
AL_settings.active_input_names = {'alpha','relBeta','ampgrad','offsetgrad'};
% AL_settings.active_input_names = {'freq','alpha','relBeta','ampgrad','offsetgrad'};

% Active learned outputs. turbulenceMetrics already computes all of these.
AL_settings.active_output_names = {'TI_mean','aniso_mean','CV_U','CV_TI','dUdy_slope','dTIdy_slope'};

% Input registry. The DB keys are kept in the current nested structure.
input_defs = struct('name',{},'key',{},'label',{},'range',{},'default',{});
k = 0;
k = k+1; input_defs(k) = struct('name','freq',       'key','actuation.freq',       'label','Frequency [Hz]',           'range',config.OPT_settings.freqRange,       'default',config.OPT_settings.fixedFreq);
k = k+1; input_defs(k) = struct('name','alpha',      'key','actuation.alpha',      'label','\alpha [deg]',             'range',config.OPT_settings.alphaRange,      'default',mean(config.OPT_settings.alphaRange));
k = k+1; input_defs(k) = struct('name','relBeta',    'key','actuation.relBeta',    'label','relBeta [-]',              'range',config.OPT_settings.relBetaRange,    'default',mean(config.OPT_settings.relBetaRange));
k = k+1; input_defs(k) = struct('name','ampgrad',    'key','actuation.ampgrad',    'label','Amplitude gradient [deg]', 'range',config.OPT_settings.ampgradRange,    'default',0);
k = k+1; input_defs(k) = struct('name','offsetgrad', 'key','actuation.offsetgrad', 'label','Offset gradient [deg]',    'range',config.OPT_settings.offsetgradRange, 'default',0);
AL_settings.input_defs = input_defs;

% Output registry.
% role:
%   target     -> penalize distance from target
%   penalty    -> lower-is-better, usually target = 0
%   diagnostic -> model/plot, but do not include in target cost
%
% targetWeight affects the exploitation/target score.
% exploreWeight affects the exploration uncertainty score.
% scale = 'data' means normalise with the current training-output std.
output_defs = struct('name',{},'key',{},'label',{},'role',{}, ...
    'target',{},'targetWeight',{},'exploreWeight',{},'scale',{});
k = 0;
k = k+1; output_defs(k) = struct('name','TI_mean',      'key','metrics.TI_mean',      'label','TI mean',       'role','target',  'target',AL_settings.targets.TI_mean,     'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
k = k+1; output_defs(k) = struct('name','aniso_mean',   'key','metrics.aniso_mean',   'label','Anisotropy',    'role','penalty', 'target',0,                              'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
k = k+1; output_defs(k) = struct('name','CV_U',         'key','metrics.CV_U',         'label','CV_U',          'role','penalty', 'target',0,                              'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
k = k+1; output_defs(k) = struct('name','CV_TI',        'key','metrics.CV_TI',        'label','CV_TI',         'role','penalty', 'target',0,                              'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
k = k+1; output_defs(k) = struct('name','dUdy_slope',   'key','metrics.dUdy_slope',   'label','dU/dy slope',   'role','target',  'target',AL_settings.targets.dUdy_slope,  'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
k = k+1; output_defs(k) = struct('name','dTIdy_slope',  'key','metrics.dTIdy_slope',  'label','dTI/dy slope',  'role','target',  'target',AL_settings.targets.dTIdy_slope,'targetWeight',1.0, 'exploreWeight',1.0, 'scale','data');
AL_settings.output_defs = output_defs;

% GA/acquisition settings
AL_settings.ga = struct();
AL_settings.ga.Display = 'off';
AL_settings.ga.PopulationBase = 80;
AL_settings.ga.PopulationPerVar = 10;
AL_settings.ga.MaxGenerations = 100;
AL_settings.ga.UseParallel = false;

% Target mode settings are defined above.

% Attach AL settings to config so every objective call and saved record has
% one complete run configuration object.
config.AL_settings = AL_settings;
save(fullfile(config.root_dir, "activeLearningConfig.mat"), "AL_settings", "config", "configFile");


%% Initialize Command Window Logging
diaryFile = fullfile(root_dir, 'optimization_log.txt');
diary(diaryFile);
disp("--- Starting Optimization Run ---");
disp("Date/Time: " + string(datetime('now')));
disp("Active inputs:  " + strjoin(string(AL_settings.active_input_names), ", "));
disp("Active outputs: " + strjoin(string(AL_settings.active_output_names), ", "));


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
    laserDashboard = LaserDashboard(laserControl); %#ok<NASGU>
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
