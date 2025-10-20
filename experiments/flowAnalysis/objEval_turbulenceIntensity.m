function [J, J_comp, metrics, fields] = objEval_turbulenceIntensity(PIVfolder)
%% Automated flow field analysis for active turbulence grid (ATG) PIV optimization
targetTI = 0.2;
doPlot = true;

% Objective function weights
wTI = 0.6;  % weight for target TI deviation
wH1 = 0.01;  % weight for velocity gradient homogeneity
wH2 = 0.01;  % weight for turbulence intensity homogeneity
wH3 = 0.28;  % weight for homogeneity of turbulence intensity coefficient of variation
wA  = 0.1;  % weight for anisotropy

D = loadpiv(PIVfolder);
x = D.x; y = D.y;
u = D.u; v = D.v;
% vort = D.vort;
u(isnan(u)) = 0;
v(isnan(v)) = 0;

% xRange = [-0.1877 0.0667]; % cropping away some low correlation edges
% yRange = [-0.1164 0.1396];
% xRange = [-0.1608 0.0667]; % Was required for 20251017_ATG_bayes_opt_2 - cam2
% yRange = [-0.078 0.1396];
xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
yRange = [-0.0650 0.1396];

[x_crop,y_crop,u_crop,v_crop] = cropFields(xRange,yRange,x,y,u,v);

[metrics, fields] = turbulenceMetrics(u_crop,v_crop,x_crop,y_crop,doPlot); % Calculate turbulence intensity metrics


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

J_comp.J_TI = J_TI;
J_comp.J_hom_velgrad = J_hom_velgrad;
J_comp.J_hom_TIgrad = J_hom_TIgrad;
J_comp.J_hom_CV = J_hom_CV;
J_comp.J_aniso = J_aniso;

end
