%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
clear
clear global bnc triggerDelay optPIV_settings recIdx optResults
global bnc
global triggerDelay
global optPIV_settings
global recIdx
global optResults

optResults = [];
recIdx = 1;

verbose = true;
ext_trigger = false;
% nRec = 3;

Uinf = 4; % Free-stream velocity at 200 RPM wind tunnel motor rate
rho_air = 1.225; % Density air [kg/m^3]
c = 0.105; % Chord [m]
R = 0.6; % Span [m]


%% Configure experiment and write config file
% root_dir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250725_test\";
root_dir = "C:\PIV_SANDBOX\20250814_test_run\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
% camera_exe = "R:\ENG_Breuer_Shared\agehrke\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";
camera_exe = "C:\Users\agehrke\Downloads\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";
% This needs to be the project containing the most recent calibration and
% LVS files and include a dummy/template case:
davis_project_source = "C:\PIV_SANDBOX\davis_project_source\"; 
configFile = fullfile(root_dir, "experiment_config.json");
% experimental PIV parameters
eset = struct( ...
    'acquisition_freq_Hz', 50, ...
    'delta_t_us', 132, ...
    'pulse_width_us', 5, ...
    'nDoubleFrames', 100, ...
    'ext_trigger', ext_trigger ...
);
% Communication parameters
cset = struct( ...
    'bnc_connection', "COM7", ...
    'laser_connection', "COM9", ...
    'camOne_connection', "192.168.1.10", ...
    'camTwo_connection', "192.168.3.10" ...
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
% We need a communication protocol between c++ and Matlab and it's not
% worth it at the moment !!!
%
% camera_cmd = camera_exe + " " + configFile;
% status = system(camera_cmd);

%% Initialize Galil board and motors
InitMotors_pitchingWing();
% Define kinematic parameters:
freqVec = [5];
nRec = length(freqVec);
pitchA = 60;
np = 20;
plotting = true;

% Wait until systems ready
pause(1)
disp("Ready to start acquisition loop")


%% Set up optimization loop parameters
optPIV_settings.g = g;
optPIV_settings.m = m;
optPIV_settings.np = np;
optPIV_settings.dt = dt;
optPIV_settings.RCN = RCN;
optPIV_settings.plotting = plotting;
optPIV_settings.config = config;
optPIV_settings.Uinf = Uinf;
optPIV_settings.rho_air = rho_air;
optPIV_settings.c = c;
optPIV_settings.R = R;

return


%% Tare wing
g.command(['SH' AllMotNam(m)]); % Turn on motors
setMotorPID(g, m, true)
simpleHome(g, m, 'pos', 90, 'JGspeed', 20);
pause(1)
g.command('DPB=0');
setMotorPID(g, m, false)

return


%% Fine tuning
simpleHome(g, m, 'pos', -2, 'JGspeed', 10);
pause(1)
g.command('DPB=0');
setMotorPID(g, m, false)

return


%% START LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for reci = 1:nRec

    % recIdx = reci;
    % optPiv_objFcn(freqVec(reci), pitchA);
    % C_T(reci) = optResults(recIdx).C_T;
    % F_T(reci) = optResults(recIdx).F_T;


    %% Arm the system
    % bnc_arm(bnc);
    % pause(0.5)


    %% Trigger if using software mode
    % if ~ext_trigger
    %     bnc_software_trigger(bnc);
    % end
    triggerDelay = 5 / freqVec(reci); % Skip first n cycles
    [results, motorStruct] = pitchingWingMotion(g, m, freqVec(reci), pitchA, np, dt, RCN, plotting);


    %% Transfer raw PIV to processing directory
    % waitForDownloadCycle(config.log_path, 60);
    % transfer_files(config.raw_PIV_dir, config.davis_templ_mraw, reci, "mraw");


    %% Process PIV
    % processPIV(config.davis_exe, config.davis_lvs_file, config.davis_set_file);


    %% Transfer processed PIV data to storage directory
    % transfer_files(config.davis_templ_dir, config.proc_PIV_dir, reci, "vc7");


    %% Analyze PIV
    % VC7Folder = fullfile(config.proc_PIV_dir, sprintf('ms%04d', reci));
    % F_T(reci) = momentumDeficit(VC7Folder, Uinf, rho_air);
    % VTipMean(reci) = meanTipSpeed(c, deg2rad(pitchA), freqVec(reci));
    % C_T(reci) = F_T(reci) ./ (0.5 * rho_air * c * R * VTipMean(reci).^2);
    % C_T(reci) = F_T(reci) ./ (0.5 * rho_air * c * R * Uinf.^2)

    % disp("Current F_T = " + num2str(F_T(reci)) + ", Current C_T = " + num2str(C_T(reci)))
end
%% END LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Disarm system, cleanup
bnc_disarm(bnc)
% shutDownLaser(); % TODO: IMPLEMENT RS232 CONTROL


%% Display results:
% F_T
% C_T

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
