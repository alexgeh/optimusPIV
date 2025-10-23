function [metrics, fields] = turbulenceMetrics(u,v,x,y,doPlot)
%% Compute turbulence intensity, homogeneity and anisotropy measures from time-resolved velocity fields.
%
% Input:
%   u(x,y,t), v(x,y,t) : time-resolved velocity components [Ny x Nx x Nt]
%   x, y               : coordinate vectors (1D, monotonic)
%
% Output:
%   metrics : 


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

    %% time-resolved gradients
    % for framei = 1:size(u,3)
    % [~, dudy(:,:,framei)] = gradient(u(:,:,framei), dx, dy);
    % end
    % dudy_mean = mean(dudy(:),'omitnan');

    %% --- (1) Velocity gradient measure ---
    [dUdx, dUdy] = gradient(U, dx, dy);
    [dVdx, dVdy] = gradient(V, dx, dy);

    velgrad_field = sqrt(dUdx.^2 + dUdy.^2 + dVdx.^2 + dVdy.^2);
    velgrad_mean = mean(velgrad_field(:),'omitnan');
    velgradupdown_mean = mean(dUdy(:),'omitnan');


    %% --- (2) Turbulence intensity and its gradient ---
    TI = sqrt(u_rms.^2 + v_rms.^2) ./ (sqrt(U.^2 + V.^2) + eps);

    [dTI_dx, dTI_dy] = gradient(TI, dx, dy);
    TIgrad_field = sqrt(dTI_dx.^2 + dTI_dy.^2);
    TIgrad_mean = mean(TIgrad_field(:),'omitnan');
    TIgrad_std = std(TIgrad_field(:),'omitnan');


    %% --- (3) Homogeneity CV ---
    TI_mean = mean(TI(:),'omitnan');
    TI_std  = std(TI(:),'omitnan');
    CV = TI_std / (TI_mean + eps);


    %% --- Anisotropy measure (2D surrogate) ---
    % Using difference between normal stresses, normalized
    aniso_field = abs(uu - vv) ./ (uu + vv + eps);
    aniso_mean = mean(aniso_field,'all','omitnan');

    % Frobenius norm explicitly:
    % J_aniso = mean(sqrt(uu.^2 + vv.^2) ./ (uu + vv + eps),'all','omitnan');


    %% Package metrics and fields
    metrics.TI_mean = TI_mean;
    metrics.TI_std = TI_std;
    metrics.TIgrad_mean = TIgrad_mean;
    metrics.TIgrad_std = TIgrad_std;
    metrics.CV = CV;
    metrics.velgrad_mean = velgrad_mean;
    metrics.velgradupdown_mean = velgradupdown_mean;
    metrics.aniso_mean = aniso_mean;

    fields.U = U;
    fields.V = V;
    fields.velgrad = velgrad_field;
    fields.dUdy = dUdy;
    fields.TI = TI;
    fields.TIgrad = TIgrad_field;
    fields.aniso = aniso_field;


    %% Plotting
    if doPlot
        figure(201)
        limits = [TI_mean-TI_std TI_mean+TI_std];
%         limits = [0 0.03];
        nLevel = 25;
        toplot = TI;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Turbulence intensity field')

        figure(202)
        limits = [0.5*TIgrad_mean 1.5*TIgrad_mean];
%         limits = [0 0.2];
        nLevel = 25;
        toplot = TIgrad_field;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Turbulence intensity gradient field')

        figure(203)
        limits = [0.5*velgrad_mean 1.5*velgrad_mean];
        nLevel = 25;
        toplot = velgrad_field;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Velocity gradient field')

        figure(204)
        limits = [0.5*aniso_mean 1.5*aniso_mean];
        nLevel = 25;
        toplot = aniso_field;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Anisotropy field')

        figure(205)
        toplot = u(:,:,10);
        limits = [mean(toplot,'all')-mean(std(toplot),'all') mean(toplot,'all')+mean(std(toplot),'all')];
        nLevel = 25;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('stream-wise velocity 1')

        figure(206)
        toplot = u(:,:,11);
        limits = [mean(toplot,'all')-mean(std(toplot),'all') mean(toplot,'all')+mean(std(toplot),'all')];
        nLevel = 25;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('stream-wise velocity 2')

        figure(207)
        limits = sort([0.5*velgradupdown_mean 1.5*velgradupdown_mean]);
        nLevel = 25;
        toplot = dUdy;
        [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colorbar()
        clim(limits)
        title('Velocity gradient dU/dy field')
    end
end
