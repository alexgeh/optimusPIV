%% WORKS WELL!

% Parameters
N = 15; 
nVert = 8; nHoriz = 7;
M = 4;
tSim = linspace(0,1,9);

% Base settings
A_base = 60; % degrees
f_base = 1; % Hz

for m = 1:M
    phiA   = A_base * ones(N,1);
    f      = f_base * ones(N,1);
    phi0   = zeros(N,1);

    % Define phase offset patterns per mode
    theta0 = zeros(N,1); % default
    switch m
        case 1 % All in phase
            theta0(:) = 0;

        case 2 % Vertical vs horizontal 180° out of phase
            theta0(1:nVert)       = 0;      % vertical motors
            theta0(nVert+1:end)   = pi/2;     % horizontal motors

        case 3 % Gradient phase across vertical motors
            theta0(1:nVert)       = linspace(0,pi,nVert);
            theta0(nVert+1:end)   = linspace(0,pi,nHoriz);

        case 4 % Checkerboard alternating 0/π
            pattern = repmat([0 pi/2],1,ceil(N/2));
            theta0 = pattern(1:N)';
    end

    % Visualize and export
    outFolder = sprintf('Amode_%d',m);
    visualize_ATG(phiA,f,theta0,phi0,tSim,outFolder,sprintf('mode%d',m));
end
