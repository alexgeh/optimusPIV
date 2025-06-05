clear

% ==========================================
% FRAME STRADDLING TIMING DIAGRAM
% ==========================================
%  v Camera Trigger
%  |--- Exposure A ---|--- Exposure B ---|--- Exposure A ---|--- Exposure B ---|
%    Laser Pulse 1 ^   ^ Laser Pulse 2
%                  |<->|
%                   dt

%% Define parameters and calculate timings
% ==========================================
% USER-DEFINED PARAMETERS (IN MICROSECONDS)
% ==========================================
acquisition_freq_Hz = 1000;     % Acquisition frequency in Hz (defines time between double frames)
delta_t_us = 20;                % Delay between Frame A & Frame B in microseconds
pulse_width_us = 5;             % Laser pulse width in microseconds
ext_trigger = false;             % true: "EXT" (external trigger :PULSEce), or false: "IMM" (immediate internal trigger)
nFrames = 20000;                % Number of double frames to capture

% Setup parameters:
% depend on the hardware and should usually not be changed (only for initial setup, or a change in hardware)
resetBNC = false;               % True: factory reset BNC, false: don't reset
nChannels = 4;                  % Number of channels used on the BNC (standard = 4)
cmdWaitTime = 0.1;              % Time to wait between commands (to not overload the BNC with commands)
interframe_t_us = 1.944;        % Inter-frame time of the camera (governed by hardware - Here: Photron Nova R2 - Source: William Spinelli - Photron)
camera_delay_us = 1.8;          % Delay between TRIGGER/CLOCK IN and image acquisition in microseconds [NOTE: CHECK MANUAL OR DETERMINE EXPERIMENTALLY]
laser_delay_us = 0;             % Delay between TRIGGER IN and laser firing in microseconds [NOTE: CHECK MANUAL OR DETERMINE EXPERIMENTALLY]
safety_factor = 1.4;            % Safety margin for laser gate
trigger_pulse_width_us = 100;   % Pulse width used for trigger signals (!! NOT LASER !!)

% Convert microseconds to seconds for device programming
delta_t_s = delta_t_us * 1e-6;
pulse_width_s = pulse_width_us * 1e-6;
interframe_t_s = interframe_t_us * 1e-6;
camera_delay_s = camera_delay_us * 1e-6;
laser_delay_s = laser_delay_us * 1e-6;
trigger_pulse_width_s = trigger_pulse_width_us * 1e-6;

% Calculate timings between cameras and laser pulses
frame_period_s = 1 / acquisition_freq_Hz;
camera_clock_frequency = acquisition_freq_Hz; % We will program the camera to take two frames per TRIGGER/CLOCK IN 
laser_pulse2_time = frame_period_s/2 - laser_delay_s + camera_delay_s; % Beginning of Frame B
laser_pulse1_time = laser_pulse2_time - delta_t_s; % End of Frame A
% laser_gate_duration = pulse_width_s * safety_factor;
laser_gate_time = laser_pulse1_time - (safety_factor - 1) * pulse_width_s/2; % Start of laser gate opening (safety factor
laser_gate_duration_s = laser_pulse2_time + pulse_width_s + (safety_factor - 1) * pulse_width_s - laser_pulse1_time;


%% Connect to BNC and program in timings
% ==========================================
% CONNECT TO BNC MODEL 577 :PULSE GENERATOR
% ==========================================
bnc = serialport("COM7", 115200); % Adjust COM port as needed
bnc.configureTerminator('CR/LF');

% query(bnc, "*RST"); % Reset BNC settings
% pause(2.0);

% ==========================================
% CONFIGURE GENERAL BNC SETTINGS
% ==========================================
query(bnc, ":SPULSE:MODE BURST");
pause(cmdWaitTime)
query(bnc, sprintf(":SPULSE:BCOUNTER %d", nFrames)); % Set the overall number of burst cycles
pause(cmdWaitTime)
for channeli = 1:nChannels
    query(bnc, sprintf(":PULSE%d:OUTPUT:MODE TTL", channeli));
    pause(cmdWaitTime)
    query(bnc, sprintf(":PULSE%d:CMODE BURST", channeli));
    pause(cmdWaitTime)
end

% ==========================================
% CONFIGURE CLOCK OUTPUT FOR CAMERA SYNC
% ==========================================
query(bnc, sprintf(":SPULSE:PERIOD %f", frame_period_s));

% ==========================================
% CONFIGURE GATE SIGNAL (Channel A) - Laser Enable
% ==========================================
query(bnc, sprintf(":PULSE1:WIDTH %e", laser_gate_duration_s));
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE1:DELAY %e", laser_gate_time)); % Delay for correct timing for the second laser pulse (frame B)
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE1:BCOUNTER %d", nFrames)); % Limit pulses to 2*nFrames (one time for each laser pulse A & B)
pause(cmdWaitTime)

% ==========================================
% CONFIGURE LASER PULSE 1 (Frame A - Channel B)
% ==========================================
query(bnc, sprintf(":PULSE2:WIDTH %e", pulse_width_s));
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE2:DELAY %e", laser_pulse1_time)); % Delay for correct timing for the first laser pulse (frame A)
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE2:BCOUNTER %d", nFrames)); % Limit pulses to nFrames
pause(cmdWaitTime)

% ==========================================
% CONFIGURE LASER :PULSE 2 (Frame B - Channel C)
% ==========================================
query(bnc, sprintf(":PULSE3:WIDTH %e", pulse_width_s));
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE3:DELAY %e", laser_pulse2_time)); % Delay for correct timing for the second laser pulse (frame B)
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE3:BCOUNTER %d", nFrames)); % Limit pulses to nFrames
pause(cmdWaitTime)

% ==========================================
% CONFIGURE CAMERA TRIGGER (Channel D)
% ==========================================
query(bnc, sprintf(":PULSE4:WIDTH %e", trigger_pulse_width_s));
pause(cmdWaitTime)
query(bnc, sprintf(":PULSE4:BCOUNTER %d", nFrames)); % Limit pulses to nFrames
pause(cmdWaitTime)


%% ==========================================
%  ARM THE SYSTEM - SET TRIGGER SOURCE
%  ==========================================
query(bnc, ":SPULSE:TRIGGER:MODE TRIG"); % External trigger input
query(bnc, ":SPULSE:STATE ON"); % This arms the system
if ext_trigger
    disp("BNC setup and armed - Waiting for external trigger.")
else
    % Software trigger launch sequence
    disp("BNC setup and armed - SOFTWARE TRIGGER LAUNCHING IN")
    disp(">>> 5 <<<")
    pause(1)
    disp(">>> 4 <<<")
    pause(1)
    disp(">>> 3 <<<")
    pause(1)
    disp(">>> 2 <<<")
    pause(1)
    disp(">>> 1 <<<")
    pause(1)
    query(bnc, "*TRG");
    disp("LAUNCHING BNC WITH SOFTWARE TRIGGER")
end
