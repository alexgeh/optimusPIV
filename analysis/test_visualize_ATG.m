%% Test out the ATG visualization script

nVertMotors  = 8;   % vertical axes (columns)
nHorizMotors = 7;   % horizontal axes (rows)

% Actuation parameters
phiA   = ones(nVertMotors+nHorizMotors,1)*60;     % amplitude [deg]
f      = ones(nVertMotors+nHorizMotors,1)*0.5;    % frequency [Hz]
theta0 = linspace(0,2*pi,nVertMotors+nHorizMotors)'; % phase offsets
phi0   = ones(nVertMotors+nHorizMotors,1)*15;       % mean offset

% Time vector
tSim = linspace(0,10,200);

visualize_ATG(phiA, f, theta0, phi0, tSim);
