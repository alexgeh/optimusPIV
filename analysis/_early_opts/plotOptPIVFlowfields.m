%% Plot wind turbine PIV (20250415 - Bridget, Alex - Wind Tunnel)
%
%  20250813 - Alexander Gehrke

clear

rootDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250812_bayes_opt\";
pivDataDir = fullfile(rootDir, "proc_PIV");
plotDir = fullfile(rootDir, "plots");

savePlots = true;


%% Turbine and case parameters
Uinf = 4; % Free-stream velocity
c = 0.105; % Turbine diameter


%% Load case
msi = 30;
caseString = sprintf('ms%04d', msi);
caseDir = fullfile(pivDataDir, caseString);

[u, v, cr, x, y] = readVC7Folder(caseDir);
x = x(:,:,1);
y = y(:,:,1);


% Window where flow field analysis is being done at (cropping away edges
% and actuators
xRange = [-0.2 0.06];
yRange = [-0.05 0.14];

% Find indices for flow field window
firstXIdx = find(x(1,:) > xRange(1), 1, "first");
firstYIdx = find(y(:,1) > yRange(2), 1, "last");
lastXIdx = find(x(1,:) < xRange(2), 1, "last");
lastYIdx = find(y(:,1) < yRange(1), 1, "first");
cropXIdx = firstXIdx:lastXIdx;
cropYIdx = firstYIdx:lastYIdx;

% Create cropped fields:
cr_crop = cr(cropYIdx,cropXIdx);

x_crop = x(cropYIdx,cropXIdx);
y_crop = y(cropYIdx,cropXIdx);
u_crop = u(cropYIdx,cropXIdx,:);
v_crop = v(cropYIdx,cropXIdx,:);

Uinf_corr_factor = Uinf / mean(u_crop(1,end,:));

u = u * Uinf_corr_factor;
v = v * Uinf_corr_factor;
u_crop = u(cropYIdx,cropXIdx,:);
v_crop = v(cropYIdx,cropXIdx,:);

% Normalized and shifted coordinate system
x_c = x / c;
y_c = y / c;
x_crop_c = x_crop / c;
y_crop_c = y_crop / c;
[nX, nY, nFrames] = size(u);

% Calculate velocity magnitude and vorticity
[vel_mag, o] = deal(nan(size(u)));
for framei = 1:nFrames
    vel_mag(:,:,framei) = (u(:,:,framei).^2 + v(:,:,framei).^2).^0.5;
    o(:,:,framei) = curl(x,y,u(:,:,framei),v(:,:,framei));
end

vel_mag_crop = vel_mag(cropYIdx,cropXIdx,:);
o_crop = o(cropYIdx,cropXIdx,:);

u_mean = mean(u_crop,3);
v_mean = mean(v_crop,3);


%% Plotting and colormap settings
darkMode = false;
variousColorMaps();

% return

%% Plot contour map of stream-wise velocity
nLevel = 20; % Number of contour levels
cLimits = [0.5 1.5];

outFolder = fullfile(plotDir, caseString, "u_comp");
ensureTopLevelFolder(fullfile(plotDir, caseString));
ensureTopLevelFolder(outFolder);

figure();
for framei = 1:nFrames
    toplot = u_crop(:,:,framei) / Uinf;
    [C,h] = contourf(x_crop_c(:,1:end), y_crop_c(:,1:end), toplot, [min(toplot, [], "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "omitnan")]);
    set(h,'linestyle','none')
    
    clim(cLimits)
    colormap(RdYlGn_cmap);
    cb = colorbar();
    ylabel(cb, 'u / U_{\infty}','FontSize',16)

    axis equal

    xlabelg("$$x / c$$"); ylabelg("$$y / c$$");

%     xlim([-0.25 1.15])
%     ylim([0 0.625])

    if savePlots
        fname = sprintf("u_comp_%.5d.png", framei);
        export_fig(fullfile(outFolder, fname), '-png', '-transparent', '-opengl','-r600');
    else
        pause(0.1)
    end
end


%% Plot contour map of vorticity omega_z
nLevel = 20; % Number of contour levels
cLimits = 10*[-1 1];

outFolder = fullfile(plotDir, caseString, "vorticity");
ensureTopLevelFolder(fullfile(plotDir, caseString));
ensureTopLevelFolder(outFolder);

figure();
for framei = 1:nFrames
    toplot = o_crop(:,:,framei) * c / Uinf;
    [C,h] = contourf(x_crop_c, y_crop_c, toplot, [min(toplot, [], "all", "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "all", "omitnan")]);
    set(h,'linestyle','none')
    
    clim(cLimits)
    colormap(oColorMap);
    cb = colorbar();
    ylabel(cb, '\omega_z c / U_{\infty}','FontSize',16);

    axis equal

    xlabelg("$$x / c$$"); ylabelg("$$y / c$$");


%     xlim([-0.25 1.15])
%     ylim([0 0.61])

    if savePlots
        fname = sprintf("vorticity_%.5d.png", framei);
        export_fig(fullfile(outFolder, fname), '-png', '-opengl','-r600');
        % export_fig(fullfile(folder, fname), '-png', '-transparent', '-opengl','-r600');
    else
        pause(0.1)
    end
end

return


%% Plot contour map of velocity magnitude
nLevel = 20; % Number of contour levels
cLimits = [0.5 1.5];

outFolder = fullfile(plotDir, "vel_mag");

figure();
for framei = 1:nFrames
    toplot = vel_mag_crop(:,:,framei) / Uinf;
    [C,h] = contourf(x_crop_c(:,1:end), y_crop_c(:,1:end), toplot, [min(toplot, [], "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "omitnan")]);
    set(h,'linestyle','none')
    
    clim(cLimits)
    colormap(RdYlGn_cmap);
    cb = colorbar();
    ylabel(cb, 'mag(u) / U_{\infty}','FontSize',16)

    axis equal

    xlabelg("$$x / c$$"); ylabelg("$$y / c$$");

%     xlim([-0.25 1.15])
%     ylim([0 0.625])

    if savePlots
        fname = sprintf("vel_mag_%.5d.png", framei);
        export_fig(fullfile(outFolder, fname), '-png', '-transparent', '-opengl','-r600');
    else
        pause(0.1)
    end
end



%% Plot contour map of average stream-wise velocity
nLevel = 20; % Number of contour levels
cLimits = [0.5 1.5];

outFolder = fullfile(plotDir, "u_comp");

figure();
toplot = u_mean / Uinf;
[C,h] = contourf(x_crop_c, y_crop_c, toplot, [min(toplot, [], "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "omitnan")]);
set(h,'linestyle','none')

clim(cLimits)
colormap(RdYlGn_cmap);
cb = colorbar();
ylabel(cb, 'u / U_{\infty}','FontSize',16)

axis equal
xlabelg("$$x / c$$"); ylabelg("$$y / c$$");

%     xlim([-0.25 1.15])
%     ylim([0 0.625])

if savePlots
    fname = sprintf("u_comp_%.5d.png", framei);
    export_fig(fullfile(outFolder, fname), '-png', '-transparent', '-opengl','-r600');
end


