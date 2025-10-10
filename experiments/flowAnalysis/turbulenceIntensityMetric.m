function metrics = turbulenceIntensityMetric(u,v,x,y,doPlot)
% objective_TI  Computes objective function for TI optimization
%
% Inputs:
%   u,v      : velocity fields [ny,nx,nFrames]
%   x,y      : coordinate grids [ny,nx]
%   targetTI : target turbulence intensity (e.g. 0.2)
%   doPlot   : logical, true = make diagnostic plots
%
% Outputs:
%   J        : scalar objective function
%   metrics  : struct with detailed components

% ---- 1. Mean and fluctuations ----
Umag  = sqrt(u.^2 + v.^2);              % instantaneous magnitude
Umean = mean(Umag,3);                   % time-mean magnitude field [ny,nx]

u_mean = mean(u,3);
v_mean = mean(v,3);
u_fluc = u - u_mean;
v_fluc = v - v_mean;

uu = mean(u_fluc.^2,3);
vv = mean(v_fluc.^2,3);
uu_mean = mean(uu(:),'omitnan');
vv_mean = mean(vv(:),'omitnan');

% ---- 2. Local TI field ----
TI_field = sqrt(0.5*(uu+vv)) ./ (Umean+eps);
TI_mean  = mean(TI_field(:),'omitnan');

% ---- 3. Homogeneity (relative std of TI field) ----
TI_std       = std(TI_field(:),'omitnan');
inhomogeneity  = TI_std / TI_mean;  % Coefficient of variation (CV), 0 = perfectly homogeneous

% ---- 4. Anisotropy (u vs v fluctuations) ----
anisotropy = mean( abs(uu-vv) ./ (uu+vv+eps), 'all','omitnan');

% ---- 6. Pack metrics ----
metrics.TI_field    = TI_field;
metrics.TI_mean     = TI_mean;
metrics.inhomogeneity = inhomogeneity;
metrics.anisotropy  = anisotropy;

% ---- 7. Optional plots ----
if nargin > 5 && doPlot
    figure('Name','TI diagnostics','Position',[100 100 1200 400]);
    
    subplot(1,3,1);
    surf(x,y,TI_field,'EdgeColor','none'); view(2); axis equal tight;
    colorbar; title(sprintf('TI field (mean=%.3f)',TI_mean));
    xlabel('x'); ylabel('y');
    clim([TI_mean-0.25*TI_mean TI_mean+0.25*TI_mean])
    
    subplot(1,3,2);
    surf(x,y,uu,'EdgeColor','none'); view(2); axis equal tight;
    colorbar; title('u''^2 variance');
    xlabel('x'); ylabel('y');
    clim([uu_mean-0.25*uu_mean uu_mean+0.25*uu_mean])
    
    subplot(1,3,3);
    surf(x,y,vv,'EdgeColor','none'); view(2); axis equal tight;
    colorbar; title('v''^2 variance');
    xlabel('x'); ylabel('y');
    clim([vv_mean-0.25*vv_mean vv_mean+0.25*vv_mean])
end
end
