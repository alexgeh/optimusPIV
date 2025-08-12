%% Initialize flapping wing setup
%  Author: Alexander Gehrke - 20250312
% clear


ipAddressGalil = "192.168.4.20";


%% Motor/Galil board parameters:
% Flap Motor
encoderHigh = true;

m(1).ms = 8000/360; % Number of counts for 1 degree
m(1).n = 'B';   % Assign motor names
% m(1).KDhigh = 5; % PID motor control during motion
% m(1).KPhigh = 15;
% m(1).KIhigh = 0.01;
% m(1).KDhigh = 30; % PID motor control during motion
% m(1).KPhigh = 60;
% m(1).KIhigh = 0.1;
m(1).KDlow = 4; % PID motor control before and after motion (avoid unstable response)
m(1).KPlow = 6;
m(1).KIlow = 0.01;
% m(1).KDhigh = 2478; % PID motor control during motion
% m(1).KPhigh = 335;
% m(1).KIhigh = 13;
m(1).KDhigh = 75; % PID motor control during motion
m(1).KPhigh = 90;
m(1).KIhigh = 0.02;
% m(1).KDhigh = 4000; % PID motor control during motion
% m(1).KPhigh = 700;
% m(1).KIhigh = 20;

dt_gal = 2^-10; % Galil time step
RCN = 4; % Encoder sampling parameter
[m.RCN] = deal(RCN); % Set encoder recording frequency for all motors
Nm = length(m);

% dt = 0.005; % [s] Discritization time step. Ideally has to be higher than galil time step (same for both motors)
dt = 0.05; % [s] Discritization time step. Ideally has to be higher than galil time step (same for both motors)


%% Galil Setup:
disp("Connecting to Galil motion controller (" + num2str(ipAddressGalil) + ")")
g = ConnectGalil(ipAddressGalil);

% g.command([ m(1).n])

% Motor tuning:
pause(1e-3)
setMotorPID(g, m(1), encoderHigh); % FLAP
pause(1e-3)

g.programDownloadFile('sineAmpInit.dmc');
pause(0.2)
disp('Initialize sine amp motor.')
g.command('XQ#sAmInit');
pause(3.0)


%% Data acquisition structure:
% NI.rate = 1000; % [Hz] Scan rate for NI card
% NI.channels = 0:6; % Analog input channels to use
% NI.device = 'Dev3'; % Device name - needs to be determined using daq.getDevices
% NI.calmat = 'FT43243.mat'; % Load cell calibration matrix
% % Calculate NI recording time using motion frequency and period data. Can
% % be overridden to enable continual sampling if set to 0. Inadvisable.
% NI_timesafety = 1; % [s] Safety margin to account for initial motion time, losses in code
% % NI.duration = np/f + NI_timesafety; % [s] Amount of time NI will record data for



