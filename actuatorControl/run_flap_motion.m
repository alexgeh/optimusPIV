function [exp, m] = run_flap_motion(f, np, pitchA)
%% run_flap_motion
%  This function runs a flapping motion using a Galil motor controller.
%  Inputs:
%    f      - Flapping frequency [Hz]
%    np     - Number of base cycles
%    pitchA - Flapping amplitude [deg]
%
%  Author: Adapted from Alexander Gehrke - 20250312

close all
clearvars -except f np pitchA
run('InitMotors_pitchingWing.m') % Initialize motors

%% Run Options
flapSwitch = 1;
strokeOffset = 0; % Stroke motion zero position offset [deg] (22.5 for deformation measurements)

reset = false; % Reset position on limit switches
loadcell = false; % [true, false] Do you want to take loadcell data?
plotting = true; % [true, false] Do you want plots or not?

zerotime = 1; % Time for zero force measurements [s]
waittime = 1; % Pause time between operations (e.g. homing, zero-meas, etc)

% Create measurement parameter vector
para.np = np;
Tex = 1 ./ f;
T = round(Tex/2,2)*2; % Round times to discretization precision
phase_shift = 0;
para.T = T;
para.beta0 = phase_shift;
f = 1/T;
para.f = f;
texp = 0:dt:np*T; % Experiment time vector

%% Define motors and motions:
fp_A = f; % Stroke frequency [Hz]
f_B = @(t) (pitchA * cos(2*pi*fp_A*t + strokeOffset)); % sinusoidal function

m(1).t = texp; % Physical time vector
m(1).x = f_B(m(1).t); % motion vector

%% Preview desired motor trajectory
if plotting
    figure; plot(m(1).t, m(1).x)
end

%% Galil Setup
g.command('DPA=0;')
g.command(['SH' AllMotNam(m)]); % Turn on motors
pause(1e-3)
[m.RCN] = deal(RCN); % Set encoder recording frequency for all motors

% NI setup
if loadcell
    disp("Recording load cell bias.")
    NI.zeros = zeroforce(NI, 'time', zerotime);
    pause(waittime);
end

%% Homing procedure
disp("Move to start position")
pos = [m(1).x(1)];
simpleHome(g, m, 'pos', pos, 'JGspeed', 10);
pause(1e-3)

%% Start main motion
disp("Starting motion")
pause(2)
if loadcell
    exp = Galil_motion(g, m, NI);
else
    exp = Galil_motion(g, m);
end

g.command('ST');
pause(1)

%% PLOT
if plotting
    figure, hold on,
    plot(m(1).t, m(1).x)
    plot(exp(1).t, exp(1).x)
    legend('ideal','rec')
end
end


