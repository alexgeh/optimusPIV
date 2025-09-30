% recombine_modes_demo.m
clear; close all;

% Motor grid
nVert = 8;
nHoriz = 7;
N = nVert + nHoriz;

% Define modes
Psi = defineModes(nVert, nHoriz);

% Example modal parameters
A_modes    = [25; 20; 35; 40];          % amplitudes in deg
phi_modes  = [0; pi/2; pi/4; pi];       % modal phases
phi0_modes = [0; 0; 0; 0];              % DC offsets
f_common   = 1;                         % Hz

% Collapse to per-motor signals
[phiA, f_mot, theta0, phi0] = ...
    combine_modes_to_motors(Psi, A_modes, phi_modes, phi0_modes, f_common);

% Time vector
tSim = linspace(0,4,401);

m = 1;

% Visualize and export
outFolder = sprintf('recomb_mode_%d',m);
visualize_ATG(phiA,f_common,theta0,phi0,tSim,outFolder,'frame');

return

signals = zeros(N,length(tSim));
for j = 1:N
    signals(j,:) = phi0(j) + phiA(j)*sin(2*pi*f_mot(j)*tSim + theta0(j));
end

% Visualization
figure;
subplot(2,1,1)
plot(Psi,'LineWidth',2);
xlabel('Motor index'); ylabel('\psi (mode shape)');
legend('Mode 1','Mode 2','Mode 3','Mode 4');
title('Physics-informed mode shapes');

subplot(2,1,2)
plot(tSim,signals,'LineWidth',1.2);
xlabel('Time (s)'); ylabel('Motor angle (deg)');
title('Recombined per-motor signals');
