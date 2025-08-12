%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
clear
clear global bnc triggerDelay
global bnc
global triggerDelay

verbose = true;
ext_trigger = false;
% nRec = 3;

Uinf = 4; % Free-stream velocity at 200 RPM wind tunnel motor rate
rho_air = 1.225; % Density air [kg/m^3]


%% Configure experiment and write config file
% root_dir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250725_test\";
root_dir = "C:\PIV_SANDBOX\20250812_test_run\";
davis_exe = "C:\DaVis\win64\DaVis.exe";
camera_exe = "R:\ENG_Breuer_Shared\agehrke\MATLAB\2025_optimusPIV\cameraControl\PhotronCameraCtrl\SDKConfirmTool\Debug\SDKConfirmTool.exe";
% This needs to be the project containing the most recent calibration and
% LVS files and include a dummy/template case:
davis_project_source = "C:\PIV_SANDBOX\davis_project_source\"; 
configFile = fullfile(root_dir, "experiment_config.json");
% experimental PIV parameters
eset = struct( ...
    'acquisition_freq_Hz', 100, ...
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

% Initialize Galil board and motors
InitMotors_pitchingWing();
% Define kinematic parameters:
freqVec = [1,2,3];
nRec = length(freqVec);
pitchA = 20;
np = 10;
plotting = true;

% Wait until systems ready
pause(1)
disp("Ready to start acquisition loop")

return


%% Tare wing
g.command(['SH' AllMotNam(m)]); % Turn on motors
setMotorPID(g, m, true)
simpleHome(g, m, 'pos', 90, 'JGspeed', 10);
pause(1)
g.command('DPB=0');

return


%% Fine tuning
simpleHome(g, m, 'pos', -2, 'JGspeed', 10);
pause(1)
g.command('DPB=0');
setMotorPID(g, m, false)

return


%% START LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for reci = 1:nRec

    %% Arm the system
    bnc_arm(bnc);
    pause(0.5)
    
    
    %% Trigger if using software mode
    % if ~ext_trigger
    %     bnc_software_trigger(bnc);
    % end
    triggerDelay = 4 / freqVec(reci); % Skip first n cycles
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
    % disp("Current F_T = " + num2str(F_T(reci)))

end
%% END LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Disarm system, cleanup
bnc_disarm(bnc)
% shutDownLaser(); % TODO: IMPLEMENT RS232 CONTROL


%% Display results:
% F_T

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
