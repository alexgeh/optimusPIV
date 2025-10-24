function [J, J_comp, metrics, fields] = objEval_turbulenceIntensity_TIgrad(PIVfolder)
%% Automated flow field analysis for active turbulence grid (ATG) PIV optimization

legitFrames = 1:190; % ADDED TO REPROCESS FILE WITHOUT FAULTY DATA (20251023)

targetTI = 0.2;
% targetdudy = -2.5;
targetTIdy = -0.2;

doPlot = true;


% Objective function weights (used for run 6 = 20251024)
wTI = 0.6927;  % weight for target TI deviation
wH1 = 0.089;  % weight for velocity gradient homogeneity
wH2 = 0.14;  % weight for turbulence intensity homogeneity
wH3 = 0.0437;  % weight for homogeneity of turbulence intensity coefficient of variation
wA  = 0.0346;  % weight for anisotropy
% wTI = 0.2192;  % weight for target TI deviation
% wH1 = 0.1533;  % weight for velocity gradient homogeneity
% wH2 = 0.5496;  % weight for turbulence intensity homogeneity
% wH3 = 0.0434;  % weight for homogeneity of turbulence intensity coefficient of variation
% wA  = 0.0344;  % weight for anisotropy

D = loadpiv(PIVfolder, "frameRange", legitFrames);
x = D.x; y = D.y;
u = D.u; v = D.v;
% vort = D.vort;
u(isnan(u)) = 0;
v(isnan(v)) = 0;

% xRange = [-0.1877 0.0667]; % cropping away some low correlation edges
% yRange = [-0.1164 0.1396];
% xRange = [-0.1608 0.0667]; % Was required for 20251017_ATG_bayes_opt_2 - cam2
% yRange = [-0.078 0.1396];
% xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
% yRange = [-0.0650 0.1396];
% xRange = [-0.18 0.0642];
xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
yRange = [-0.111 0.137];

[x_crop,y_crop,u_crop,v_crop] = cropFields(xRange,yRange,x,y,u,v);
% x_crop = x;
% y_crop = y;
% u_crop = u;
% v_crop = v;

[metrics, fields] = turbulenceMetrics(u_crop,v_crop,x_crop,y_crop,doPlot); % Calculate turbulence intensity metrics


%% Calculate optimization loss functions
% J_TI - Squared pointwise deviations (L2 error of TI):
TI_err_field = fields.TI - targetTI;
J_TI_raw = mean( (TI_err_field(:)).^2 );       % spatial mean of squared error
J_TI = J_TI_raw / (targetTI + eps);           % normalized by target (scalar)
% J_TI = abs(TI_metrics.TI_mean - targetTI) / targetTI; % Relative error (L1)

% J_hom - homogeneity metric:
% Target dudy
% dUdy_err_field = fields.dudy - targetdudy;
% dUdy_err_field = fields.dUdy - targetdudy;
% J_hom_dUdy_raw = mean( (dUdy_err_field(:)).^2 );       % spatial mean of squared error
% J_hom_dUdy = J_hom_dUdy_raw / (abs(targetdudy) + eps);           % normalized by target (scalar)
J_hom_velgrad = metrics.velgrad_mean / (1 + metrics.velgrad_mean);

J_hom_TIgrad = metrics.TIgrad_mean / (1 + metrics.TIgrad_mean);
% J_hom_dTIdy = metrics.dTIdy_mean; % This will be our turbulence intensity gradient target
dTIdy_err_field = fields.dTIdy - targetTIdy;
J_hom_dTIdy_raw = mean( (dTIdy_err_field(:)).^2 );       % spatial mean of squared error
J_hom_dTIdy = J_hom_dTIdy_raw / (abs(targetTIdy) + eps);           % normalized by target (scalar)

J_hom_CV = metrics.CV / (1 + metrics.CV); % Bounded coefficient of variation
% J_hom = w1*J_hom_velgrad + w2*J_hom_TIgrad + w3*J_hom_CV;

% J_aniso - anisotropy metric:
% J_aniso = metrics.aniso_mean; % Unbounded
J_aniso = metrics.aniso_mean / (1 + metrics.aniso_mean); % Bounded

J = wTI*J_TI + wH1*J_hom_velgrad + wH2*J_hom_dTIdy + wH3*J_hom_CV + wA*J_aniso;

J_comp.J_TI = J_TI;
% J_comp.J_hom_dUdy = J_hom_dUdy;
J_comp.J_hom_velgrad = J_hom_velgrad;
J_comp.J_hom_TIgrad = J_hom_TIgrad;
J_comp.J_hom_dTIdy = J_hom_dTIdy;
J_comp.J_hom_CV = J_hom_CV;
J_comp.J_aniso = J_aniso;

end
