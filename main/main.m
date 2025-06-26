%% Main script - Launches the entire optimusPIV thing
%
%  Author: Alexander Gehrke - 20250605
clear
verbose = true;
ext_trigger = false;


%% Configure experiment and write config file
root_dir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250613_test\";
configFile = fullfile(root_dir, "experiment_config.json");
% PIV parameters
pset = struct( ...
    'acquisition_freq_Hz', 100, ...
    'delta_t_us', 110, ...
    'pulse_width_us', 5, ...
    'nDoubleFrames', 200, ...
    'ext_trigger', ext_trigger ...
);
% Communication parameters
cset = struct( ...
    'bnc_connection', "COM7", ...
    'laser_connection', "COM9", ...
    'camOne_connection', "192.168.1.10", ...
    'camTwo_connection', "192.168.3.10" ...
);
write_experiment_config(root_dir, pset, cset, verbose);


%% Read config (for confirmation)
config = read_experiment_config(configFile, false);

root_dir = config.root_dir;
pset = config.PIV_settings;
cset = config.COM_settings;

% disp(pset.acquisition_freq_Hz);
% disp(pset.bnc_connection);

return


%% Setup Equipment
% Initialize BNC
bnc = bnc_init(cset.bnc_connection);
% Program BNC with current parameters
bnc_program(bnc, pset.acquisition_freq_Hz, pset.delta_t_us, pset.pulse_width_us, pset.nDoubleFrames);
% Initialize & arm cameras
% camera_launch(configFile); % NOT IMPLEMENTED YET


%% Arm the system
bnc_arm(bnc);


%% Trigger if using software mode
if ~ext_trigger
    bnc_software_trigger(bnc);
end


%% Disarm system, cleanup
% bnc_disarm(bnc)


%% Transfer data


%% Process PIV


