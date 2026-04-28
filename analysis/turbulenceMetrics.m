function [metrics, fields] = turbulenceMetrics(u,v,x,y,doPlot)
%% Compute turbulence intensity, homogeneity and anisotropy measures from time-resolved velocity fields.
%
% Input:
%   u(x,y,t), v(x,y,t) : time-resolved velocity components [Ny x Nx x Nt]
%   x, y               : coordinate vectors (1D, monotonic)
%
% Output:
%   metrics : structure containing calculated values
%   fields  : structure containing generated 2D fields

    %% Grid spacing
    dx = x(1,2) - x(1,1);
    dy = y(2,1) - y(1,1);

    %% --- Time-averaged fields ---
    U = mean(u,3,'omitnan');
    V = mean(v,3,'omitnan');

    %% --- Fluctuations ---
    u_fluct = u - U;   % subtract mean at each point
    v_fluct = v - V;

    %% --- RMS fields (for TI) ---
    u_rms = sqrt(mean(u_fluct.^2,3,'omitnan'));
    v_rms = sqrt(mean(v_fluct.^2,3,'omitnan'));

    %% --- Reynolds stresses (for anisotropy) ---
    uu = mean(u_fluct.^2,3,'omitnan');
    vv = mean(v_fluct.^2,3,'omitnan');

    %% --- (1) Velocity gradient & Homogeneity ---
    [dUdx, dUdy] = gradient(U, dx, dy);
    [dVdx, dVdy] = gradient(V, dx, dy);

    velgrad_field = sqrt(dUdx.^2 + dUdy.^2 + dVdx.^2 + dVdy.^2);
    velgrad_mean = mean(velgrad_field(:),'omitnan');
    dUdy_mean = mean(dUdy(:),'omitnan');
    
    % NEW: CV of Velocity (Uniformity of mean flow)
    U_mean = mean(U(:), 'omitnan');
    CV_U = std(U(:), 'omitnan') / (U_mean + eps);

    % NEW: Robust Signed Slope: Fit a 1st order polynomial to the y-profile
    U_y_profile = mean(U, 2, 'omitnan'); % Average across columns (x-direction)
    y_vec = y(:,1); % Extract vertical coordinate vector
    
    valid_U_idx = ~isnan(U_y_profile);
    if sum(valid_U_idx) >= 2
        p_U = polyfit(y_vec(valid_U_idx), U_y_profile(valid_U_idx), 1);
        dUdy_slope = p_U(1);
    else
        dUdy_slope = NaN; % Fallback if data is too sparse
    end

    %% --- (2) Turbulence intensity and its gradient ---
    TI = sqrt(u_rms.^2 + v_rms.^2) ./ (sqrt(U.^2 + V.^2) + eps);

    [dTI_dx, dTI_dy] = gradient(TI, dx, dy);
    TIgrad_field = sqrt(dTI_dx.^2 + dTI_dy.^2);
    TIgrad_mean = mean(TIgrad_field(:),'omitnan');
    TIgrad_std = std(TIgrad_field(:),'omitnan');

    dTIdy_mean = mean(dTI_dy(:),'omitnan');

    % Homogeneity CV of TI
    TI_mean = mean(TI(:),'omitnan');
    TI_std  = std(TI(:),'omitnan');
    CV_TI = TI_std / (TI_mean + eps);

    % NEW: Robust Signed Slope for TI
    TI_y_profile = mean(TI, 2, 'omitnan');
    
    valid_TI_idx = ~isnan(TI_y_profile);
    if sum(valid_TI_idx) >= 2
        p_TI = polyfit(y_vec(valid_TI_idx), TI_y_profile(valid_TI_idx), 1);
        dTIdy_slope = p_TI(1);
    else
        dTIdy_slope = NaN;
    end

    %% --- (3) Anisotropy measure (2D surrogate) ---
    % Using difference between normal stresses, normalized
    aniso_field = abs(uu - vv) ./ (uu + vv + eps);
    aniso_mean = mean(aniso_field,'all','omitnan');

    %% Package metrics and fields
    % Original metrics
    metrics.TI_mean = TI_mean;
    metrics.TI_std = TI_std;
    metrics.TIgrad_mean = TIgrad_mean;
    metrics.TIgrad_std = TIgrad_std;
    metrics.dTIdy_mean = dTIdy_mean;
    metrics.CV = CV_TI; % Maintained for backward compatibility
    metrics.velgrad_mean = velgrad_mean;
    metrics.dudy_mean = dUdy_mean;
    metrics.aniso_mean = aniso_mean;
    
    % New multi-objective metrics
    metrics.CV_U = CV_U;
    metrics.CV_TI = CV_TI;
    metrics.dUdy_slope = dUdy_slope;
    metrics.dTIdy_slope = dTIdy_slope;

    fields.U = U;
    fields.V = V;
    fields.velgrad = velgrad_field;
    fields.dUdy = dUdy;
    fields.TI = TI;
    fields.TIgrad = TIgrad_field;
    fields.dTIdy = dTI_dy;
    fields.aniso = aniso_field;

    %% Plotting
    if doPlot
        figure(201)
        limits = [TI_mean-TI_std TI_mean+TI_std];
        nLevel = 25;
        toplot = TI;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Turbulence intensity field')

        figure(202)
        limits = [0.5*TIgrad_mean 1.5*TIgrad_mean];
        nLevel = 25;
        toplot = TIgrad_field;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Turbulence intensity gradient field')

        figure(203)
        limits = [0.5*velgrad_mean 1.5*velgrad_mean];
        nLevel = 25;
        toplot = velgrad_field;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Velocity gradient field')

        figure(204)
        limits = [0.5*aniso_mean 1.5*aniso_mean];
        nLevel = 25;
        toplot = aniso_field;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Anisotropy field')

        figure(205)
        toplot = u(:,:,1);
        toplotMean = mean(toplot,'all','omitnan');
        toplotStd = mean(std(toplot,'omitnan'),'all');
        limits = [toplotMean-toplotStd toplotMean+toplotStd];
        nLevel = 25;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('stream-wise velocity first frame')

        figure(206)
        toplot = u(:,:,end);
        toplotMean = mean(toplot,'all','omitnan');
        toplotStd = mean(std(toplot,'omitnan'),'all');
        limits = [toplotMean-toplotStd toplotMean+toplotStd];
        nLevel = 25;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('stream-wise velocity last frame')

        figure(207)
        limits = sort([0.5*dUdy_mean 1.5*dUdy_mean]);
        nLevel = 25;
        toplot = dUdy;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Velocity gradient dU/dy field')

        figure(208)
        toplot = dTI_dy;
        limits = [mean(toplot,'all')-mean(std(toplot),'all') mean(toplot,'all')+mean(std(toplot),'all')];
        nLevel = 25;
        [~,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Turbulence Intensity gradient dTI/dy field')
    end
end
