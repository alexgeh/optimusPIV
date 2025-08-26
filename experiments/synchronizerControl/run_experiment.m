clear;

para = getOptPivPara(file);

% Experimental parameters
bnc_connection = "COM7";   % Channel used for BNC connection
acquisition_freq_Hz = 100; % Acquisition frequency (Hz)
delta_t_us = 110;          % Delay between Frame A & B (us)
pulse_width_us = 5;        % Laser pulse width (us)
nDoubleFrames = 200;       % Number of double frames
ext_trigger = true;        % true: external trigger, false: software trigger

% Initialize BNC
bnc = bnc_init(bnc_connection);

% Program BNC with current parameters
bnc_program(bnc, acquisition_freq_Hz, delta_t_us, pulse_width_us, nDoubleFrames);

% Arm the system
bnc_arm(bnc);

% Trigger if using software mode
if ~ext_trigger
    bnc_software_trigger(bnc);
end

% bnc_disarm(bnc)
