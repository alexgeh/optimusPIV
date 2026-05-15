%% Single-parameter TI model for active turbulence grid
% Assumes:
%   X(:,1) = amplitude
%   X(:,2) = offset
%   Y(:,1) = average turbulence intensity
%
% Models tested:
%   1) RMS-angle collapse:
%        chi = sqrt(offset^2 + amplitude^2/2)
%
%   2) Finite-angle projected-blockage collapse:
%        chi = sqrt(<sin^2(offset + amplitude*sin(phi))>)
%
%   3) Full quadratic response surface:
%        TI = c0 + c1*A + c2*O + c3*A^2 + c4*O^2 + c5*A*O
%
%   4) Data-driven elliptical one-parameter collapse:
%        chi = sqrt([A O] W [A O]')
%        TI = TI0 + C*chi^n
clear
close all; clc;

load("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20260426_optDB.mat")

optDB = optDB(219:end);

inputNames  = {'actuation.ampl', 'actuation.offset'};
outputNames = {'metrics.TI_mean'};

fprintf('Extracting data from database...\n');
X = actLearn_extractMatrixFromDB(optDB, inputNames);
Y = actLearn_extractMatrixFromDB(optDB, outputNames);


%% ---------------- USER SETTINGS ----------------
angleUnit = 'deg';      % 'deg' or 'rad'
nPhi      = 2000;       % integration points for projected blockage
makePlots = true;

%% ---------------- LOAD DATA ----------------
A_raw  = X(:,1) / 2;
O_raw  = X(:,2);
TI     = Y(:,1);

valid = isfinite(A_raw) & isfinite(O_raw) & isfinite(TI);
A_raw = A_raw(valid);
O_raw = O_raw(valid);
TI    = TI(valid);

switch lower(angleUnit)
    case 'deg'
        A = deg2rad(A_raw);
        O = deg2rad(O_raw);
        angleDisplayFactor = 180/pi;
        angleLabel = 'deg';
    case 'rad'
        A = A_raw;
        O = O_raw;
        angleDisplayFactor = 1;
        angleLabel = 'rad';
    otherwise
        error('angleUnit must be either ''deg'' or ''rad''.');
end

N = numel(TI);

%% ---------------- EFFECTIVE PARAMETERS ----------------

% 1) RMS angle:
% theta(t) = offset + amplitude*sin(phi)
% <theta^2> = offset^2 + amplitude^2/2
chi_rms = sqrt(O.^2 + 0.5*A.^2);

% 2) Finite-angle projected blockage:
% chi_block = sqrt(<sin^2(theta(t))>)
phi = linspace(0, 2*pi, nPhi);
theta_inst = O + A.*sin(phi);             % implicit expansion: N x nPhi
chi_block = sqrt(mean(sin(theta_inst).^2, 2));

%% ---------------- FIT MODELS ----------------

% RMS-angle power law: TI = TI0 + C*chi^n
fit_rms_power = fitPowerLaw(chi_rms, TI);

% RMS-angle quadratic: TI = c0 + c1*chi + c2*chi^2
fit_rms_quad = fitQuadratic1D(chi_rms, TI);

% Blockage power law: TI = TI0 + C*chi^n
fit_block_power = fitPowerLaw(chi_block, TI);

% Blockage quadratic: TI = c0 + c1*chi + c2*chi^2
fit_block_quad = fitQuadratic1D(chi_block, TI);

% Full quadratic surface in amplitude and offset
fit_surface_quad = fitQuadraticSurface(A, O, TI);

% Data-driven elliptical one-parameter model
fit_ellipse_power = fitEllipticPower(A, O, TI);

%% ---------------- MODEL PREDICTIONS ----------------

TI_rms_power     = fit_rms_power.predict(chi_rms);
TI_rms_quad      = fit_rms_quad.predict(chi_rms);
TI_block_power   = fit_block_power.predict(chi_block);
TI_block_quad    = fit_block_quad.predict(chi_block);
TI_surface_quad  = fit_surface_quad.predict(A, O);
TI_ellipse_power = fit_ellipse_power.predict(A, O);

%% ---------------- MODEL METRICS ----------------

metrics = [
    modelMetrics(TI, TI_rms_power,     fit_rms_power.nParams,     "RMS angle power")
    modelMetrics(TI, TI_rms_quad,      fit_rms_quad.nParams,      "RMS angle quadratic")
    modelMetrics(TI, TI_block_power,   fit_block_power.nParams,   "Projected blockage power")
    modelMetrics(TI, TI_block_quad,    fit_block_quad.nParams,    "Projected blockage quadratic")
    modelMetrics(TI, TI_surface_quad,  fit_surface_quad.nParams,  "Full quadratic surface")
    modelMetrics(TI, TI_ellipse_power, fit_ellipse_power.nParams, "Elliptic power collapse")
];

metrics = sortrows(metrics, "RMSE");
disp(metrics);

%% ---------------- PRINT MODEL EQUATIONS ----------------

fprintf('\nRMS-angle power model:\n');
fprintf('TI = %.6g + %.6g * chi^{%.6g}\n', ...
    fit_rms_power.TI0, fit_rms_power.C, fit_rms_power.n);
fprintf('chi = sqrt(offset^2 + amplitude^2/2)\n');

fprintf('\nProjected-blockage power model:\n');
fprintf('TI = %.6g + %.6g * B_eff^{%.6g}\n', ...
    fit_block_power.TI0, fit_block_power.C, fit_block_power.n);
fprintf('B_eff = sqrt(<sin^2(offset + amplitude*sin(phi))>)\n');

fprintf('\nFull quadratic surface:\n');
fprintf('TI = c0 + c1*A + c2*O + c3*A^2 + c4*O^2 + c5*A*O\n');
disp(fit_surface_quad.coeffs);

fprintf('\nElliptic power-collapse model:\n');
fprintf('TI = %.6g + %.6g * chi^{%.6g}\n', ...
    fit_ellipse_power.TI0, fit_ellipse_power.C, fit_ellipse_power.n);
fprintf('chi = sqrt([A O] * W * [A O]'')\n');
disp('W = ');
disp(fit_ellipse_power.W);

%% ---------------- PLOTS ----------------

if makePlots

    %% Figure 1: 3D response surface
    figure('Name','3D response surface','Color','w');
    hold on; box on; grid on;

    scatter3(A_raw, O_raw, TI, 60, TI, 'filled');

    nGrid = 80;
    A_grid_raw = linspace(min(A_raw), max(A_raw), nGrid);
    O_grid_raw = linspace(min(O_raw), max(O_raw), nGrid);
    [AA_raw, OO_raw] = meshgrid(A_grid_raw, O_grid_raw);

    switch lower(angleUnit)
        case 'deg'
            AA = deg2rad(AA_raw);
            OO = deg2rad(OO_raw);
        case 'rad'
            AA = AA_raw;
            OO = OO_raw;
    end

    TI_grid = fit_surface_quad.predict(AA, OO);

    surf(AA_raw, OO_raw, TI_grid, ...
        'FaceAlpha', 0.35, ...
        'EdgeColor', 'none');

    xlabel(['Amplitude [' angleLabel ']']);
    ylabel(['Offset [' angleLabel ']']);
    zlabel('Average TI');
    title('Quadratic response surface');
    view(135, 25);
    colorbar;

    %% Figure 2: single-parameter collapses
    figure('Name','Single-parameter collapses','Color','w');
    tiledlayout(1,3, 'Padding','compact', 'TileSpacing','compact');

    % RMS collapse
    nexttile; hold on; box on; grid on;
    scatter(chi_rms*angleDisplayFactor, TI, 50, 'filled');

    chi_line = linspace(min(chi_rms), max(chi_rms), 300).';
    plot(chi_line*angleDisplayFactor, fit_rms_power.predict(chi_line), ...
        'LineWidth', 2);
    plot(chi_line*angleDisplayFactor, fit_rms_quad.predict(chi_line), ...
        '--', 'LineWidth', 2);

    xlabel(['\chi_{RMS} [' angleLabel ']']);
    ylabel('Average TI');
    title('RMS-angle collapse');
    legend('Data','Power law','Quadratic','Location','best');

    % Projected blockage collapse
    nexttile; hold on; box on; grid on;
    scatter(chi_block, TI, 50, 'filled');

    chi_line = linspace(min(chi_block), max(chi_block), 300).';
    plot(chi_line, fit_block_power.predict(chi_line), ...
        'LineWidth', 2);
    plot(chi_line, fit_block_quad.predict(chi_line), ...
        '--', 'LineWidth', 2);

    xlabel('B_{eff}');
    ylabel('Average TI');
    title('Projected-blockage collapse');
    legend('Data','Power law','Quadratic','Location','best');

    % Elliptic collapse
    nexttile; hold on; box on; grid on;
    chi_ellipse = fit_ellipse_power.chi(A, O);
    scatter(chi_ellipse*angleDisplayFactor, TI, 50, 'filled');

    chi_line = linspace(min(chi_ellipse), max(chi_ellipse), 300).';
    plot(chi_line*angleDisplayFactor, fit_ellipse_power.predictChi(chi_line), ...
        'LineWidth', 2);

    xlabel(['\chi_{ellipse} [' angleLabel ']']);
    ylabel('Average TI');
    title('Data-driven elliptic collapse');
    legend('Data','Power law','Location','best');

    %% Figure 3: measured vs predicted
    figure('Name','Measured vs predicted','Color','w');
    hold on; box on; grid on;

    plot(TI, TI_rms_power,     'o', 'MarkerSize', 7, 'DisplayName','RMS power');
    plot(TI, TI_block_power,   's', 'MarkerSize', 7, 'DisplayName','Blockage power');
    plot(TI, TI_surface_quad,  '^', 'MarkerSize', 7, 'DisplayName','Surface quadratic');
    plot(TI, TI_ellipse_power, 'd', 'MarkerSize', 7, 'DisplayName','Elliptic power');

    minVal = min([TI; TI_rms_power; TI_block_power; TI_surface_quad; TI_ellipse_power]);
    maxVal = max([TI; TI_rms_power; TI_block_power; TI_surface_quad; TI_ellipse_power]);
    plot([minVal maxVal], [minVal maxVal], 'k--', 'LineWidth', 1.5, ...
        'DisplayName','Perfect prediction');

    xlabel('Measured TI');
    ylabel('Predicted TI');
    title('Measured vs predicted');
    legend('Location','best');
    axis equal;
    xlim([minVal maxVal]);
    ylim([minVal maxVal]);

    %% Figure 4: residuals
    figure('Name','Residual diagnostics','Color','w');
    tiledlayout(2,2, 'Padding','compact', 'TileSpacing','compact');

    residualPlot(A_raw, TI - TI_rms_power, ...
        ['Amplitude [' angleLabel ']'], 'RMS power residuals');

    residualPlot(O_raw, TI - TI_rms_power, ...
        ['Offset [' angleLabel ']'], 'RMS power residuals');

    residualPlot(A_raw, TI - TI_block_power, ...
        ['Amplitude [' angleLabel ']'], 'Blockage power residuals');

    residualPlot(O_raw, TI - TI_block_power, ...
        ['Offset [' angleLabel ']'], 'Blockage power residuals');

    %% Figure 5: TI contours from the preferred physical models
    figure('Name','TI contours from reduced models','Color','w');
    tiledlayout(1,2, 'Padding','compact', 'TileSpacing','compact');

    % RMS model contour
    nexttile; hold on; box on;
    chi_grid_rms = sqrt(OO.^2 + 0.5*AA.^2);
    TI_grid_rms = fit_rms_power.predict(chi_grid_rms);

    contourf(AA_raw, OO_raw, TI_grid_rms, 20, 'LineColor','none');
    scatter(A_raw, O_raw, 35, TI, 'filled', 'MarkerEdgeColor','k');
    xlabel(['Amplitude [' angleLabel ']']);
    ylabel(['Offset [' angleLabel ']']);
    title('RMS-angle model');
    colorbar;

    % Projected-blockage model contour
    nexttile; hold on; box on;
    TI_grid_block = zeros(size(AA));

    for ii = 1:numel(AA)
        theta_tmp = OO(ii) + AA(ii).*sin(phi);
        B_tmp = sqrt(mean(sin(theta_tmp).^2));
        TI_grid_block(ii) = fit_block_power.predict(B_tmp);
    end

    contourf(AA_raw, OO_raw, TI_grid_block, 20, 'LineColor','none');
    scatter(A_raw, O_raw, 35, TI, 'filled', 'MarkerEdgeColor','k');
    xlabel(['Amplitude [' angleLabel ']']);
    ylabel(['Offset [' angleLabel ']']);
    title('Projected-blockage model');
    colorbar;
end

%% ========================================================================
%% LOCAL FUNCTIONS
%% ========================================================================

function fit = fitPowerLaw(x, y)
    x = x(:);
    y = y(:);

    xMax = max(x);
    yMin = min(y);
    yRange = max(y) - min(y);

    if xMax <= 0
        error('x must contain at least one positive value.');
    end

    TI0_0 = yMin;
    C0    = max(yRange / xMax, eps);
    n0    = 1;

    q0 = [TI0_0, log(C0), log(n0)];

    obj = @(q) sum((y - powerModel(q, x)).^2);

    opts = optimset( ...
        'Display','off', ...
        'MaxFunEvals', 5e4, ...
        'MaxIter', 5e4);

    q = fminsearch(obj, q0, opts);

    fit.TI0 = q(1);
    fit.C   = exp(q(2));
    fit.n   = exp(q(3));
    fit.nParams = 3;
    fit.predict = @(xq) fit.TI0 + fit.C .* max(xq,0).^fit.n;
end

function yhat = powerModel(q, x)
    TI0 = q(1);
    C   = exp(q(2));
    n   = exp(q(3));

    yhat = TI0 + C .* max(x,0).^n;

    if any(~isfinite(yhat))
        yhat = inf(size(x));
    end
end

function fit = fitQuadratic1D(x, y)
    x = x(:);
    y = y(:);

    Xmat = [ones(size(x)), x, x.^2];
    coeffs = Xmat \ y;

    fit.coeffs = coeffs;
    fit.nParams = 3;
    fit.predict = @(xq) [ones(numel(xq),1), xq(:), xq(:).^2] * coeffs;
end

function fit = fitQuadraticSurface(A, O, y)
    A = A(:);
    O = O(:);
    y = y(:);

    Xmat = [ ...
        ones(size(A)), ...
        A, ...
        O, ...
        A.^2, ...
        O.^2, ...
        A.*O];

    coeffs = Xmat \ y;

    fit.coeffs = coeffs;
    fit.nParams = 6;
    fit.predict = @(Aq,Oq) reshape( ...
        [ones(numel(Aq),1), Aq(:), Oq(:), Aq(:).^2, Oq(:).^2, Aq(:).*Oq(:)] * coeffs, ...
        size(Aq));
end

function fit = fitEllipticPower(A, O, y)
    A = A(:);
    O = O(:);
    y = y(:);

    yMin = min(y);
    yRange = max(y) - min(y);

    % Initial W approximates chi^2 = O^2 + A^2/2,
    % then normalized to trace(W)=1.
    wA0 = 1/3;
    wO0 = 2/3;
    alpha0 = log(wA0 / wO0);   % logistic parameter
    beta0  = 0;                % rotation angle

    chi0 = sqrt(wA0*A.^2 + wO0*O.^2);
    C0 = max(yRange / max(chi0), eps);
    n0 = 1;

    q0 = [yMin, log(C0), log(n0), alpha0, beta0];

    obj = @(q) sum((y - ellipticPowerModel(q, A, O)).^2);

    opts = optimset( ...
        'Display','off', ...
        'MaxFunEvals', 1e5, ...
        'MaxIter', 1e5);

    q = fminsearch(obj, q0, opts);

    [W, ~, ~] = ellipseMatrix(q);

    fit.TI0 = q(1);
    fit.C   = exp(q(2));
    fit.n   = exp(q(3));
    fit.W   = W;
    fit.nParams = 5;

    fit.chi = @(Aq,Oq) sqrt(max( ...
        W(1,1).*Aq.^2 + 2*W(1,2).*Aq.*Oq + W(2,2).*Oq.^2, 0));

    fit.predictChi = @(chiq) fit.TI0 + fit.C .* max(chiq,0).^fit.n;
    fit.predict = @(Aq,Oq) fit.predictChi(fit.chi(Aq,Oq));
end

function yhat = ellipticPowerModel(q, A, O)
    [W, ~, ~] = ellipseMatrix(q);

    chi2 = W(1,1).*A.^2 + 2*W(1,2).*A.*O + W(2,2).*O.^2;
    chi = sqrt(max(chi2, 0));

    TI0 = q(1);
    C   = exp(q(2));
    n   = exp(q(3));

    yhat = TI0 + C.*chi.^n;

    if any(~isfinite(yhat))
        yhat = inf(size(A));
    end
end

function [W, weights, beta] = ellipseMatrix(q)
    alpha = q(4);
    beta  = q(5);

    % Eigenvalues constrained positive and normalized to trace = 1
    w1 = 1 / (1 + exp(-alpha));
    w2 = 1 - w1;
    weights = [w1, w2];

    R = [cos(beta), -sin(beta); sin(beta), cos(beta)];
    W = R * diag(weights) * R.';
end

function T = modelMetrics(y, yhat, k, modelName)
    y = y(:);
    yhat = yhat(:);

    n = numel(y);
    residuals = y - yhat;

    SSE = sum(residuals.^2);
    SST = sum((y - mean(y)).^2);

    RMSE = sqrt(mean(residuals.^2));
    MAE  = mean(abs(residuals));
    R2   = 1 - SSE/SST;

    % Small-sample corrected AIC
    AIC = n*log(SSE/n) + 2*k;
    if n > k + 1
        AICc = AIC + (2*k*(k+1))/(n-k-1);
    else
        AICc = NaN;
    end

    T = table(modelName, R2, RMSE, MAE, AICc, k, ...
        'VariableNames', {'Model','R2','RMSE','MAE','AICc','NumParams'});
end

function residualPlot(x, residuals, xlab, ttl)
    nexttile; hold on; box on; grid on;
    scatter(x, residuals, 45, 'filled');
    yline(0, 'k--', 'LineWidth', 1.2);
    xlabel(xlab);
    ylabel('Residual');
    title(ttl);
end