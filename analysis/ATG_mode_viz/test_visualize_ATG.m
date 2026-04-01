%% Test out the ATG visualization script
clear
close all

nVertMotors  = 8;   % vertical axes (columns)
nHorizMotors = 7;   % horizontal axes (rows)
nMotors = nVertMotors + nHorizMotors;
% Time vector
tSim = linspace(0,4,401);


%% Actuation parameters
% 'Traveling Wave'
% phiA   = ones(nVertMotors+nHorizMotors,1)*60;     % amplitude [deg]
% f      = ones(nVertMotors+nHorizMotors,1)*0.5;    % frequency [Hz]
% theta0 = linspace(0,2*pi,nVertMotors+nHorizMotors)'; % phase offsets
% phi0   = ones(nVertMotors+nHorizMotors,1)*15;       % mean offset

% Amplitude and offset gradient:
phiA   = [0*ones(nVertMotors,1); ...
    ... ones(nHorizMotors,1)*40 ...
    linspace(30,90,nHorizMotors)' ...
    ];     % amplitude [deg]
f      = 0.5*ones(nMotors,1);    % frequency [Hz]
theta0 = 0*ones(nMotors,1); % phase offsets
phi0   = [80*ones(nVertMotors,1); ...
    0*ones(nHorizMotors,1) ...
    ... linspace(0,80,nHorizMotors)' ...
    ];       % mean offset

%% 
visualize_ATG(phiA,f,theta0,phi0,tSim,fullfile('gradient'),'gradient');
% visualize_ATG(phiA, f, theta0, phi0, tSim);
