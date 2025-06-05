%% Initialize flapping wing setup
%  Author: Alexander Gehrke - 20250312
% clear


%% Motor/Galil board parameters:
% Flap Motor
encoderHigh = true;

m(1).ms = 8000/360; % Number of counts for 1 degree
m(1).n = 'B';   % Assign motor names
m(1).KDhigh = 100; % PID motor control during motion
m(1).KPhigh = 200;
m(1).KIhigh = 0.1;
% m(1).KDhigh = 34; % PID motor control during motion
% m(1).KPhigh = 50;
% m(1).KIhigh = 0.03;
m(1).KDlow = 4; % PID motor control before and after motion (avoid unstable response)
m(1).KPlow = 6;
m(1).KIlow = 0.01;

dt_gal = 2^-10; % Galil time step
RCN = 4; % Encoder sampling parameter
[m.RCN] = deal(RCN); % Set encoder recording frequency for all motors
Nm = length(m);

dt = 0.005; % [s] Discritization time step. Ideally has to be higher than galil time step (same for both motors)
% dt = 0.01; % [s] Discritization time step. Ideally has to be higher than galil time step (same for both motors)


%% Galil Setup:
g = ConnectGalil('192.168.1.20');

% Motor tuning:
pause(1e-3)
setMotorPID(g, m(1), encoderHigh); % FLAP
pause(1e-3)


%% Data acquisition structure:
% NI.rate = 1000; % [Hz] Scan rate for NI card
% NI.channels = 0:6; % Analog input channels to use
% NI.device = 'Dev3'; % Device name - needs to be determined using daq.getDevices
% NI.calmat = 'FT43243.mat'; % Load cell calibration matrix
% % Calculate NI recording time using motion frequency and period data. Can
% % be overridden to enable continual sampling if set to 0. Inadvisable.
% NI_timesafety = 1; % [s] Safety margin to account for initial motion time, losses in code
% % NI.duration = np/f + NI_timesafety; % [s] Amount of time NI will record data for




% ' The #AUTO subroutine is automatically executed on controller startup.
% #AUTO
% 
% ' Axis B Sinusoidal Amplifier Startup Code
% ' This code configures the motor and encoder polarities.
% MTB=1.0; CEB=0
% ' This code initializes the axis for sinusoidal commutation.
% ' When hall sensors are present, the BI/BC initialization mode is recommended.
% ' BI will set a precise commutation angle on the first hall sensor transition.
% BAB; BMB=2000.0000; BIB=-1; BCB
% ' The motor is now set up for sinusoidal commutation.
% ' Remove the below comment to servo the motor on startup.
% ' SHB
% 
% ' End the #AUTO subroutine
% EN


