function J = objFun_turbulenceIntensity(PIVfolder, frames)
%% Automated flow field analysis
targetTI = 0.2;
doPlot = true;

% Objective function weights
wTI = 0.5;  % weight for target TI deviation
wH1 = 0.1;  % weight for velocity gradient homogeneity
wH2 = 0.1;  % weight for turbulence intensity homogeneity
wH3 = 0.1;  % weight for homogeneity of turbulence intensity coefficient of variation
wA  = 0.2;  % weight for anisotropy

% [u, v, ~, x, y] = readVC7Folder(PIVfolder, nFrames);
% x = x(:,:,1); y = y(:,:,1); % Only keep one timestep of x-y fields
D = loadpivKB1(PIVfolder, [], "frameRange", frames);
x = D.x;
y = D.y;
u = D.u;
v = D.v;

[metrics, fields] = turbulenceMetrics(u,v,x,y,doPlot); % Calculate turbulence intensity metrics
%     fields.velgrad = velgrad_field;
%     fields.TI = TI;
%     fields.TIgrad = TIgrad_field;
%     fields.aniso = aniso_field;

%% Calculate optimization loss functions
% J_TI - Squared pointwise deviations (L2 error of TI):
TI_err_field = fields.TI - targetTI;
J_TI_raw = mean( (TI_err_field(:)).^2 );       % spatial mean of squared error
J_TI = J_TI_raw / (targetTI + eps);           % normalized by target (scalar)
% J_TI = abs(TI_metrics.TI_mean - targetTI) / targetTI; % Relative error (L1)

% J_hom - homogeneity metric:
J_hom_velgrad = metrics.velgrad_mean / (1 + metrics.velgrad_mean);
J_hom_TIgrad = metrics.TIgrad_mean / (1 + metrics.TIgrad_mean);
J_hom_CV = metrics.CV / (1 + metrics.CV); % Bounded coefficient of variation
% J_hom = w1*J_hom_velgrad + w2*J_hom_TIgrad + w3*J_hom_CV;

% J_aniso - anisotropy metric:
% J_aniso = metrics.aniso_mean; % Unbounded
J_aniso = metrics.aniso_mean / (1 + metrics.aniso_mean); % Bounded

J = wTI*J_TI + wH1*J_hom_velgrad + wH2*J_hom_TIgrad + wH3*J_hom_CV + wA*J_aniso;

end
