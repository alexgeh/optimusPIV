%% Visualize flow fields of highly resolved cases (e.g. most optimimal 
%  cases recorded at a high frequency

clear

PIVdata = 'C:\Users\agehrke\Desktop\TEMP\015_ATG_syncOpt_bestCase_GPU\';
plotDir = 'C:\Users\agehrke\Desktop\TEMP\APS_PLOTS\';

U = 5.5;
% xRange = [-0.161575 0.0649963];
% yRange = [-0.117972 0.1395690];
xRange = [-0.18 0.0642]; 
yRange = [-0.111 0.137];

D = loadpiv(PIVdata);

x = D.x; y = D.y;
u = D.u; v = D.v;
vort = D.vort;
% u(isnan(u)) = 0;
% v(isnan(v)) = 0;

nFrames = size(u,3);

u_filled = u;   % preallocate
v_filled = v;   % preallocate
vort_filled = vort;   % preallocate

for t = 1:nFrames
    frame = u(:,:,t);
    mask = isnan(frame);
    frame_filled = regionfill(frame, mask);
    u_filled(:,:,t) = frame_filled;

    frame = v(:,:,t);
    mask = isnan(frame);
    frame_filled = regionfill(frame, mask);
    v_filled(:,:,t) = frame_filled;

    frame = vort(:,:,t);
    mask = isnan(frame);
    frame_filled = regionfill(frame, mask);
    vort_filled(:,:,t) = frame_filled;
end

[x_crop,y_crop,u_crop,v_crop,vort_crop] = cropFields(xRange,yRange,x,y,u_filled,v_filled,vort_filled);
x_crop = x_crop - min(x_crop(:)); y_crop = y_crop - min(y_crop(:));

variousColorMaps();


%% Plot contour map of flow fields
nLevel = 100; % Number of contour levels
cLimits = [0.75 1.25];

mean_u = mean(u_crop(:));
std_u = std(u_crop(:));

figure();
for framei = 1:nFrames
    toplot = u_crop(:,:,framei) / mean_u; % Original flow field

    [C,h] = contourf(x_crop, y_crop, toplot, [min(toplot, [], "all", "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "all", "omitnan")]);
    set(h,'linestyle','none')

%     pcolor(x_crop, y_crop, toplot);
%     shading('interp');
    
    clim([1-1.5*std_u/mean_u 1+1.5*std_u/mean_u]);
%     clim(cLimits);
%     colormap(staryNightCmap);
%     colormap('jet');
    colormap(slanCM('jet'));
    cb = colorbar();
    cb.Label.Interpreter = 'latex';
    cb.Label.String = '$$u / \bar{U}$$';
    cb.Label.FontSize = 16;

    axis equal
    
    set(gca, 'FontSize', 14)
    xlabelg('$$x [m]$$');
    ylabelg('$$y [m]$$');

    set(gcf, 'Color', 'w')
    fname = sprintf("u_comp_%.5d.png", framei);
    export_fig(fullfile(plotDir, 'TI_opt_case', 'u_comp', fname), '-png', '-r300');
end

%% Plot contour map of flow fields
nLevel = 100; % Number of contour levels
cLimits = 40*[-1 1];

mean_u = mean(u_crop(:));
std_vort = std(vort_crop(:));

figure();
for framei = 1:nFrames
    toplot = vort_crop(:,:,framei) / mean_u; % Original flow field

    [C,h] = contourf(x_crop, y_crop, toplot, [min(toplot, [], "all", "omitnan"), linspace(cLimits(1),cLimits(2),nLevel), max(toplot, [], "all", "omitnan")]);
    set(h,'linestyle','none')

%     pcolor(x_crop, y_crop, toplot);
%     shading('interp');
    
%     clim([-1.5*std_vort 1.5*std_vort]);
    clim(cLimits);
     colormap(staryNightCmap);
%     colormap('jet');
%     colormap(slanCM('jet'));
    cb = colorbar();
    cb.Label.Interpreter = 'latex';
    cb.Label.String = '$$\omega$$';
    cb.Label.FontSize = 16;

    axis equal
    
    set(gca, 'FontSize', 14)
    xlabelg('$$x [m]$$'); ylabelg('$$y [m]$$');

    set(gcf, 'Color', 'w')
    fname = sprintf("vort_%.5d.png", framei);
    export_fig(fullfile(plotDir, 'TI_opt_case', 'vort', fname), '-png', '-r300');
end

