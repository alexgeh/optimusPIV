function [J, J_comp, metrics, fields] = objEval_turbulenceIntensity(PIVfolder, evset)
%% Automated flow field analysis for active turbulence grid (ATG) PIV optimization

D = loadpiv(PIVfolder, 'verbose', false);
x = D.x; y = D.y;
u = D.u; v = D.v;
u(isnan(u)) = 0;
v(isnan(v)) = 0;

currentXRange = [min(x,[],'all') max(x,[],'all')];
currentYRange = [min(y,[],'all') max(y,[],'all')];
width = diff(currentXRange);
height = diff(currentYRange);

xRange = [currentXRange(1)+evset.relCut*width currentXRange(2)-evset.relCut*width]; 
yRange = [currentYRange(1)+evset.relCut*height currentYRange(2)-evset.relCut*height];

[x_crop, y_crop, u_crop, v_crop] = cropFields(xRange, yRange, x, y, u, v);

% Calculate turbulence intensity metrics
[metrics, fields] = turbulenceMetrics(u_crop, v_crop, x_crop, y_crop, evset.doPlot); 


%% Calculate optimization loss functions
% J_TI - Squared pointwise deviations (L2 error of TI):
TI_err_field = fields.TI - evset.targetTI;
J_TI_raw = mean( (TI_err_field(:)).^2 );       
J_TI = J_TI_raw / (evset.targetTI + eps);           

% J_hom - homogeneity metric:
J_hom_velgrad = metrics.velgrad_mean / (1 + metrics.velgrad_mean);
J_hom_TIgrad = metrics.TIgrad_mean / (1 + metrics.TIgrad_mean);
J_hom_CV = metrics.CV / (1 + metrics.CV); 

% J_aniso - anisotropy metric:
J_aniso = metrics.aniso_mean / (1 + metrics.aniso_mean); 

J = evset.wTI*J_TI + evset.wH1*J_hom_velgrad + evset.wH2*J_hom_TIgrad + evset.wH3*J_hom_CV + evset.wA*J_aniso;

J_comp.J_TI = J_TI;
J_comp.J_hom_velgrad = J_hom_velgrad;
J_comp.J_hom_TIgrad = J_hom_TIgrad;
J_comp.J_hom_CV = J_hom_CV;
J_comp.J_aniso = J_aniso;

end
