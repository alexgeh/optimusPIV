%% Active Turbulence Grid (ATG) Modal Control Demo
% Generates per-motor amplitude, frequency, phase, and offset arrays
% from a modal basis Psi and modal coefficients.

clear; close all; clc;

%% PARAMETERS
nMotors = 15;        % 8 horizontal + 7 vertical
T       = 5;         % total time [s]
fs      = 100;       % sampling frequency [Hz]
tSim    = (0:1/fs:T)';  % time vector for visualization

%% DEFINE MODES (columns = modes, rows = motors)
% Motor order: H1..H8 (1–8), V1..V7 (9–15)

% Mode 1: global in-phase
psi1 = ones(nMotors,1);

% Mode 2: left-right antisymmetric (only horizontals)
psi2 = [ -1 -1 -1 -1  1  1  1  1  zeros(1,7) ]';

% Mode 3: spanwise ramp (H ramp -1→+1, V small weight 0.25)
H_ramp  = linspace(-1,1,8);
V_const = 0.25*ones(1,7);
psi3 = [H_ramp V_const]';

% Mode 4: checkerboard (alternate signs)
psi4 = [  1 -1  1 -1  1 -1  1 -1  1 -1  1 -1  1 -1  1 ]';

% Stack into mode matrix
Psi = [psi1 psi2 psi3 psi4];   % size = [15 x 4]


%% EXAMPLES
phi0_base = zeros(nMotors,1);   % no baseline offset initially

% Example 1: pure Mode 1 oscillation
A_modes1     = [15 0 0 0];     % amplitudes [deg]
f_modes1     = [1 0 0 0];      % Hz
theta_modes1 = [0 0 0 0];      % rad
[phiA1, f1, theta01, phi01] = modes2motors(Psi, A_modes1, f_modes1, theta_modes1, phi0_base);

% Example 2: Mode 1 + Mode 4
A_modes2     = [10 0 0 12];
f_modes2     = [1 0 0 3];
theta_modes2 = [0 0 0 pi/4];
[phiA2, f2, theta02, phi02] = modes2motors(Psi, A_modes2, f_modes2, theta_modes2, phi0_base);

% Example 3: all four modes
A_modes3     = [8 4 6 5];
f_modes3     = [1 2 1 4];
theta_modes3 = [0 pi/2 0 pi/3];
[phiA3, f3, theta03, phi03] = modes2motors(Psi, A_modes3, f_modes3, theta_modes3, phi0_base);

%% FEED INTO VISUALIZATION
% Example call (if you have the visualize_ATG function implemented):
visualize_ATG(phiA1, f1, theta01, phi01, tSim)
visualize_ATG(phiA2, f2, theta02, phi02, tSim)
visualize_ATG(3*phiA3, f3, theta03, phi03, tSim)

disp('Motor amplitudes for Example 1:');
disp(phiA1');


%% FUNCTION: Map modal inputs -> motor inputs
function [phiA, fMot, theta0, phi0] = modes2motors(Psi, A_modes, f_modes, theta_modes, phi0_base)
    % Psi: mode matrix [nMotors x nModes]
    % A_modes, f_modes, theta_modes: 1 x nModes
    % phi0_base: baseline motor offset [nMotors x 1]
    nMotors = size(Psi,1);
    nModes  = size(Psi,2);

    % Each motor's amplitude = weighted sum of modal amplitudes
    phiA = Psi * A_modes(:);

    % For now: assign same frequency/phase to each motor according to dominant mode contributions
    % → could refine by superimposing, but simple assignment is easier for start
    fMot     = Psi * f_modes(:) ./ max(Psi,[],2);   % crude mapping
    theta0   = Psi * theta_modes(:) ./ max(Psi,[],2);

    % Replace NaNs if any motor row had all zeros
    fMot(isnan(fMot))       = 0;
    theta0(isnan(theta0))   = 0;

    % Add baseline offsets
    phi0 = phi0_base(:);
end

