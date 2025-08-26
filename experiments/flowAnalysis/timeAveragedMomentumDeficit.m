function F_T  = timeAveragedMomentumDeficit(PIVfolder, Uinf, R, rho, dt_corr)
%% Automated flow field analysis
[u, v, cr, x, y] = readVC7Folder(PIVfolder);
x = x(:,:,1);
y = y(:,:,1);

[nx, ny, nFrames] = size(u);

for framei = 1:nFrames
    [o(:,:,framei), ~] = curl(x, y, u(:,:,framei), v(:,:,framei));
end

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
% u_crop = u(cropYIdx,cropXIdx,:);
% v_crop = v(cropYIdx,cropXIdx,:);
% o_crop = o(cropYIdx,cropXIdx,:);

% Uinf_corr_factor = Uinf / mean(u_crop(1,end,:));

u = u * dt_corr;
v = v * dt_corr;
u_crop = u(cropYIdx,cropXIdx,:);
v_crop = v(cropYIdx,cropXIdx,:);

% Uinf_corr = Uinf;

u_mean = mean(u_crop,"all");


%% Momentum deficit thrust calculation
dx = abs(x(1,2) - x(1,1));   % assume uniform spacing
dy = abs(y(2,1) - y(1,1));
dA = dx * dy;

% Time-average the velocity field
u_avg = mean(u, 3); % [nx, ny]
% Compute the squared average velocity
u2_avg = mean(u.^2, 3); % [nx, ny]

% Compute the integrand over the field
integrand = Uinf * u_avg - u2_avg; % [nx, ny]

% Integrate over area
T_per_span = rho * sum(integrand(:)) * dA;

% Multiply by span to get total thrust
F_T = T_per_span * R;

fprintf('Time-averaged thrust (method 3): %.4f N\n', F_T);


%% Quick plot thingy
nLevel = 25; cLimits = 1.25*[0,1];
figure(100); PIVDataPlot(x_crop, y_crop, u_crop(:,:,1) / Uinf, nLevel, cLimits);
figure(101); PIVDataPlot(x_crop, y_crop, mean(u_crop,3) / Uinf, nLevel, cLimits);

return

%% PLOTS
function PIVDataPlot(x, y, toplot, nLevel, cLimits)
%% plot u-comp contour plot - all snapshots
clf();
[C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(cLimits(1),cLimits(2),nLevel),nanmax2(toplot)]);
set(h,'linestyle','none')

clim(cLimits)
cb = colorbar();
ylabel(cb, 'u / U_{\infty}','FontSize',16)

end

%% plot u-comp contour plot - all snapshots
nLevel = 25;
cLimits = 1.25*[-1 1];
Uinf = 8.79;

figure,
for framei = 1:nFrames % Frames before 4 are botched for some reason
    % toplot = u(:,:,framei) / Uinf;
    toplot = u_crop(:,:,framei) / Uinf;

    % [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(cLimits(1),cLimits(2),nLevel),nanmax2(toplot)]);
    [C,h] = contourf(x_crop, y_crop, toplot, [nanmin2(toplot),linspace(cLimits(1),cLimits(2),nLevel),nanmax2(toplot)]);
%     [C,h] = contourf(x / D, y / D, toplot);
    set(h,'linestyle','none')

    clim(cLimits)
    % colormap(blueBlackPinkCmap);    
    cb = colorbar();
    ylabel(cb, 'u / U_{\infty}','FontSize',16)

    waitforbuttonpress();
end

%%
nLevel = 25;
cLimits = [-1 1];
figure,
for framei = 1:nFrames % Frames before 4 are botched for some reason
    % toplot = u(:,:,framei) / Uinf;
    toplot = cr_crop(:,:,framei);

    % [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(cLimits(1),cLimits(2),nLevel),nanmax2(toplot)]);
    [C,h] = contourf(x_crop, y_crop, toplot, [nanmin2(toplot),linspace(cLimits(1),cLimits(2),nLevel),nanmax2(toplot)]);
%     [C,h] = contourf(x / D, y / D, toplot);
    set(h,'linestyle','none')

    clim(cLimits)
    % colormap(blueBlackPinkCmap);    
    cb = colorbar();
    ylabel(cb, 'corr','FontSize',16)

    waitforbuttonpress();
end

end
