%% Filter results with high uncertainty

clear;

L = 0.123; % Characteristic length [m], diagonal length of panels

pivDataDir = 'R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20260417_ATG_highFreq_opt_1\proc_PIV\ms0001';
D = loadpiv(pivDataDir, "extractAllVariables");

x = D.x; y = D.y;
u = D.u; v = D.v;
vort = D.vort;
corr = D.corr;
uncU = D.uncU;
uncV = D.uncV;

% u(isnan(u)) = 0;
% v(isnan(v)) = 0;

% Re-calculate dynamic bounds
currentXRange = [min(x,[],'all') max(x,[],'all')];
currentYRange = [min(y,[],'all') max(y,[],'all')];
width = diff(currentXRange);
height = diff(currentYRange);

relCut = 0.05;
xRange = [currentXRange(1)+relCut*width currentXRange(2)-relCut*width];
yRange = [currentYRange(1)+relCut*height currentYRange(2)-relCut*height];

[x_crop, y_crop, u_crop, v_crop, vort_crop, corr_crop, uncU_crop, uncV_crop] = ...
    cropFields(xRange, yRange, x, y, u, v, vort, corr, uncU, uncV);

x_crop = x_crop - x_crop(1);
y_crop = y_crop - y_crop(1);
xData = x_crop / L;
yData = y_crop / L;

opts = struct('nLevel', 100);
opts.isLatex = true;
opts.customTicks = true;
opts.axisEqual = true;

relUncU = uncU_crop / mean(u_crop(:));
relUncV = uncV_crop / mean(u_crop(:));

uncCut = 0.05;
highUncMask = ((relUncU > uncCut) + (relUncV > uncCut)) > 0;

u_noUnc = u_crop;
u_noUnc(highUncMask) = NaN;
v_noUnc = v_crop;
v_noUnc(highUncMask) = NaN;

u_rec = fill_piv_nan(u_noUnc, 7);
v_rec = fill_piv_nan(v_noUnc, 7);

% Calculate turbulence metrics
doPlotMetrics = true; % Suppress built-in plotting to use our custom exporter
[metrics, fields] = turbulenceMetrics(u_crop, v_crop, x_crop, y_crop, doPlotMetrics);
metrics.velgrad_mean

doPlotMetrics = true; % Suppress built-in plotting to use our custom exporter
[metrics, fields] = turbulenceMetrics(u_noUnc, v_noUnc, x_crop, y_crop, doPlotMetrics);
metrics.velgrad_mean

doPlotMetrics = true; % Suppress built-in plotting to use our custom exporter
[metrics, fields] = turbulenceMetrics(u_rec, v_rec, x_crop, y_crop, doPlotMetrics);
metrics.velgrad_mean

nFrames = size(u_crop, 3);

%%
dx = x(1,2) - x(1,1);
dy = y(2,1) - y(1,1);
for iFrame = 1:nFrames
    [dudx(:,:,iFrame), dudy(:,:,iFrame)] = gradient(u_crop(:,:,iFrame), dx, dy);
end
iFrame = 6;
figure, histogram(abs(dudy(:)))
figure, histogram(abs(dudx(:)))

gradientCut = 500;
highGradientMask = ((dudy > gradientCut) + (dudx > gradientCut)) > 0;
sum(highGradientMask,"all")

u_noHighGrad = u_crop;
u_noHighGrad(gradientCut) = NaN;
v_noHighGrad = v_crop;
v_noHighGrad(gradientCut) = NaN;

doPlotMetrics = true; % Suppress built-in plotting to use our custom exporter
[metrics, fields] = turbulenceMetrics(u_noHighGrad, v_noHighGrad, x_crop, y_crop, doPlotMetrics);

metrics.velgrad_mean


%%
toplot = dUdy;
% toplot(toplot > 0.05) = NaN;
% toplot(highUncMask) = NaN;
opts.limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
% opts.limits = [0.05 0.20];
opts.cLabel = '(uncertainty u) / U';

iFrame = 1;

fig = figure(504); % Use a new figure handle to avoid interfering with any residual Phase 1 states
clf(fig);
ax = axes(fig);
set(fig, 'Color', 'w'); % Sets the figure background to white
[~, hContour] = contourf(ax, xData, yData, toplot(:,:,iFrame), 100, 'LineStyle', 'none');
colormap(ax, 'jet');
clim(ax, opts.limits);
cb = colorbar(ax);
cb.Label.Interpreter = 'latex';
ylabel(cb, opts.cLabel, 'Interpreter', 'latex');
axis(ax, 'equal');
