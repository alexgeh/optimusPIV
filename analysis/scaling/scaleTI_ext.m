%% Single-parameter TI model comparison for active turbulence grid
% Assumes:
%   X(:,1) = amplitude
%   X(:,2) = offset
%   Y(:,1) = average turbulence intensity
%
% Main idea:
%   theta(t) = offset + amplitude*sin(phi)
%
% Compares several candidate reduced parameters for TI.

clear
close all; clc;

% load("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20260426_optDB.mat")
% optDB = optDB(219:end);

load("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20260504_ATG_highFreq_actLearn_7\actLearnDB.mat")

inputNames  = {'actuation.ampl', 'actuation.offset'};
outputNames = {'metrics.TI_mean'};

fprintf('Extracting data from database...\n');
X = actLearn_extractMatrixFromDB(optDB, inputNames);
Y = actLearn_extractMatrixFromDB(optDB, outputNames);


%% ---------------- USER SETTINGS ----------------
angleUnit = 'deg';      % 'deg' or 'rad'
nPhi      = 2000;       % integration points for harmonic cycle
makePlots = true;


%% ---------------- LOAD DATA AND CONVERT TO CLASSICAL SINUSOID ----------------
% Controller convention from bfsync:
%   X(:,1) = A_cpp = endpoint-to-endpoint stroke
%   X(:,2) = O_cpp = lower/starting endpoint
%
% Physical endpoints:
%   theta_low  = O_cpp
%   theta_high = O_cpp + A_cpp
%
% Classical paper convention:
%   theta(t) = theta_0 + theta_A*sin(2*pi*f*t)
%
% where:
%   theta_0 = midpoint angle
%   theta_A = semi-amplitude

A_cpp_raw = X(:,1);   % controller stroke, not classical amplitude
O_cpp_raw = X(:,2);   % controller endpoint, not classical mean offset
TI        = Y(:,1);

% Robust endpoint conversion, also safe if A_cpp is ever negative
theta_1_raw = O_cpp_raw;
theta_2_raw = O_cpp_raw + A_cpp_raw;

theta_min_raw = min(theta_1_raw, theta_2_raw);
theta_max_raw = max(theta_1_raw, theta_2_raw);

theta0_raw = 0.5*(theta_max_raw + theta_min_raw);   % classical offset / mean angle
thetaA_raw = 0.5*(theta_max_raw - theta_min_raw);   % classical semi-amplitude

% Use classical variables for all subsequent scaling analysis
A_raw = thetaA_raw;
O_raw = theta0_raw;


%% ---------------- LOAD DATA ----------------
% A_raw  = X(:,1);
% O_raw  = X(:,2);
% TI     = Y(:,1);

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

%% ---------------- HARMONIC ANGLE HISTORY ----------------
phi = linspace(0, 2*pi, nPhi);
theta_inst = O + A.*sin(phi);       % N x nPhi, uses implicit expansion

theta_min = min(theta_inst, [], 2);
theta_max = max(theta_inst, [], 2);

%% ---------------- PHYSICALLY MOTIVATED SCALAR PARAMETERS ----------------

% 1) Time-RMS angle:
% chi = sqrt(<theta^2>)
chi_rms = sqrt(mean(theta_inst.^2, 2));

% For pure sinusoidal motion, equivalent to:
% chi_rms_exact = sqrt(O.^2 + 0.5*A.^2);

% 2) Endpoint RMS:
% Uses only lower and upper extrema of the cycle.
% This is stronger than time-RMS because amplitude is not weighted by 1/2.
chi_endpoint_rms = sqrt(0.5*(theta_min.^2 + theta_max.^2));

% 3) Mean absolute angle:
% If TI depends on average absolute obstruction.
chi_mean_abs = mean(abs(theta_inst), 2);

% 4) Peak absolute angle:
% If TI is dominated by the most obstructive part of the cycle.
chi_peak_abs = max(abs(theta_inst), [], 2);

% For pure sinusoidal motion, equivalent to:
% chi_peak_abs_exact = abs(O) + abs(A);

% 5) Upper endpoint magnitude:
% This is close to |O + A| if amplitude is positive.
chi_upper_abs = abs(theta_max);

% 6) Projected blockage, RMS:
% If projected area scales roughly with sin(theta).
chi_block_rms = sqrt(mean(sin(theta_inst).^2, 2));

% 7) Projected blockage, mean absolute:
chi_block_mean_abs = mean(abs(sin(theta_inst)), 2);

% 8) Projected blockage, peak:
chi_block_peak = max(abs(sin(theta_inst)), [], 2);

%% ---------------- FIT SIMPLE SCALAR MODELS ----------------

fit_rms_power          = fitScalarPower(chi_rms, TI);
fit_endpoint_power     = fitScalarPower(chi_endpoint_rms, TI);
fit_mean_abs_power     = fitScalarPower(chi_mean_abs, TI);
fit_peak_abs_power     = fitScalarPower(chi_peak_abs, TI);
fit_upper_abs_power    = fitScalarPower(chi_upper_abs, TI);

fit_block_rms_power    = fitScalarPower(chi_block_rms, TI);
fit_block_mean_power   = fitScalarPower(chi_block_mean_abs, TI);
fit_block_peak_power   = fitScalarPower(chi_block_peak, TI);

% Quadratic 1D versions of selected scalars
fit_rms_quad           = fitScalarQuadratic(chi_rms, TI);
fit_endpoint_quad      = fitScalarQuadratic(chi_endpoint_rms, TI);
fit_peak_abs_quad      = fitScalarQuadratic(chi_peak_abs, TI);
fit_block_rms_quad     = fitScalarQuadratic(chi_block_rms, TI);

%% ---------------- FIT DATA-DRIVEN SINGLE-PARAMETER MODELS ----------------

% Linear-combination collapse:
% chi = |O + lambda*A|
fit_linear_combo_power = fitLinearComboPower(A, O, TI);

% Shifted linear-combination collapse:
% chi = |bias + O + lambda*A|
fit_shifted_linear_power = fitShiftedLinearComboPower(A, O, TI);

% Weighted peak collapse:
% chi = |O| + lambda*|A|
fit_weighted_peak_power = fitWeightedPeakPower(A, O, TI);

% Uncentred elliptic collapse:
% chi = sqrt([A O] W [A O]')
fit_ellipse_power = fitEllipticPower(A, O, TI, false);

% Centred elliptic collapse:
% chi = sqrt(([A O] - centre) W ([A O] - centre)')
fit_centered_ellipse_power = fitEllipticPower(A, O, TI, true);

%% ---------------- FULL QUADRATIC SURFACE ----------------

fit_surface_quad = fitQuadraticSurface(A, O, TI);
quad_geom = quadraticGeometry(fit_surface_quad.coeffs);

%% ---------------- MODEL PREDICTIONS ----------------

modelNames = [
    "RMS angle power"
    "Endpoint RMS power"
    "Mean absolute angle power"
    "Peak absolute angle power"
    "Upper endpoint magnitude power"
    "Projected blockage RMS power"
    "Projected blockage mean-abs power"
    "Projected blockage peak power"
    "RMS angle quadratic"
    "Endpoint RMS quadratic"
    "Peak absolute angle quadratic"
    "Projected blockage RMS quadratic"
    "Linear combo |O + lambda A| power"
    "Shifted linear combo |b + O + lambda A| power"
    "Weighted peak |O| + lambda |A| power"
    "Elliptic power collapse"
    "Centred elliptic power collapse"
    "Full quadratic surface"
];

predMat = [
    fit_rms_power.predict(chi_rms), ...
    fit_endpoint_power.predict(chi_endpoint_rms), ...
    fit_mean_abs_power.predict(chi_mean_abs), ...
    fit_peak_abs_power.predict(chi_peak_abs), ...
    fit_upper_abs_power.predict(chi_upper_abs), ...
    fit_block_rms_power.predict(chi_block_rms), ...
    fit_block_mean_power.predict(chi_block_mean_abs), ...
    fit_block_peak_power.predict(chi_block_peak), ...
    fit_rms_quad.predict(chi_rms), ...
    fit_endpoint_quad.predict(chi_endpoint_rms), ...
    fit_peak_abs_quad.predict(chi_peak_abs), ...
    fit_block_rms_quad.predict(chi_block_rms), ...
    fit_linear_combo_power.predict(A, O), ...
    fit_shifted_linear_power.predict(A, O), ...
    fit_weighted_peak_power.predict(A, O), ...
    fit_ellipse_power.predict(A, O), ...
    fit_centered_ellipse_power.predict(A, O), ...
    fit_surface_quad.predict(A, O) ...
];

numParams = [
    fit_rms_power.nParams
    fit_endpoint_power.nParams
    fit_mean_abs_power.nParams
    fit_peak_abs_power.nParams
    fit_upper_abs_power.nParams
    fit_block_rms_power.nParams
    fit_block_mean_power.nParams
    fit_block_peak_power.nParams
    fit_rms_quad.nParams
    fit_endpoint_quad.nParams
    fit_peak_abs_quad.nParams
    fit_block_rms_quad.nParams
    fit_linear_combo_power.nParams
    fit_shifted_linear_power.nParams
    fit_weighted_peak_power.nParams
    fit_ellipse_power.nParams
    fit_centered_ellipse_power.nParams
    fit_surface_quad.nParams
];

%% ---------------- MODEL METRICS ----------------

metrics = table();

for ii = 1:numel(modelNames)
    metrics = [metrics; modelMetrics(TI, predMat(:,ii), numParams(ii), modelNames(ii))]; %#ok<AGROW>
end

metricsByRMSE = sortrows(metrics, "RMSE");
metricsByAICc = sortrows(metrics, "AICc");

disp(' ');
disp('Models ranked by RMSE:');
disp(metricsByRMSE);

disp(' ');
disp('Models ranked by AICc:');
disp(metricsByAICc);

%% ---------------- PRINT KEY MODEL EQUATIONS ----------------

fprintf('\n============================================================\n');
fprintf('KEY FITTED MODELS\n');
fprintf('============================================================\n');

fprintf('\nPeak absolute angle model:\n');
fprintf('TI = %.6g + %.6g * chi^{%.6g}\n', ...
    fit_peak_abs_power.TI0, fit_peak_abs_power.C, fit_peak_abs_power.n);
fprintf('chi = max_t |offset + amplitude*sin(phi)|\n');

fprintf('\nLinear-combination model:\n');
fprintf('TI = %.6g + %.6g * |O + lambda*A|^{%.6g}\n', ...
    fit_linear_combo_power.TI0, fit_linear_combo_power.C, fit_linear_combo_power.n);
fprintf('lambda = %.6g\n', fit_linear_combo_power.lambda);

fprintf('\nShifted linear-combination model:\n');
fprintf('TI = %.6g + %.6g * |bias + O + lambda*A|^{%.6g}\n', ...
    fit_shifted_linear_power.TI0, fit_shifted_linear_power.C, fit_shifted_linear_power.n);
fprintf('lambda = %.6g\n', fit_shifted_linear_power.lambda);
fprintf('bias   = %.6g rad = %.6g %s\n', ...
    fit_shifted_linear_power.bias, ...
    fit_shifted_linear_power.bias*angleDisplayFactor, angleLabel);

fprintf('\nWeighted peak model:\n');
fprintf('TI = %.6g + %.6g * (|O| + lambda*|A|)^{%.6g}\n', ...
    fit_weighted_peak_power.TI0, fit_weighted_peak_power.C, fit_weighted_peak_power.n);
fprintf('lambda = %.6g\n', fit_weighted_peak_power.lambda);

fprintf('\nElliptic power-collapse model:\n');
fprintf('TI = %.6g + %.6g * chi^{%.6g}\n', ...
    fit_ellipse_power.TI0, fit_ellipse_power.C, fit_ellipse_power.n);
fprintf('chi = sqrt([A O] * W * [A O]'')\n');
disp('W = ');
disp(fit_ellipse_power.W);

ellipseInfo(fit_ellipse_power.W, 'Uncentred ellipse');

fprintf('\nCentred elliptic power-collapse model:\n');
fprintf('TI = %.6g + %.6g * chi^{%.6g}\n', ...
    fit_centered_ellipse_power.TI0, fit_centered_ellipse_power.C, fit_centered_ellipse_power.n);
fprintf('chi = sqrt(([A O] - centre) * W * ([A O] - centre)'')\n');
disp('W = ');
disp(fit_centered_ellipse_power.W);
fprintf('centre A = %.6g rad = %.6g %s\n', ...
    fit_centered_ellipse_power.cA, ...
    fit_centered_ellipse_power.cA*angleDisplayFactor, angleLabel);
fprintf('centre O = %.6g rad = %.6g %s\n', ...
    fit_centered_ellipse_power.cO, ...
    fit_centered_ellipse_power.cO*angleDisplayFactor, angleLabel);

ellipseInfo(fit_centered_ellipse_power.W, 'Centred ellipse');

fprintf('\nFull quadratic response surface:\n');
fprintf('TI = c0 + c1*A + c2*O + c3*A^2 + c4*O^2 + c5*A*O\n');
disp(fit_surface_quad.coeffs);

fprintf('\nQuadratic-surface geometry:\n');
fprintf('Stationary centre A = %.6g rad = %.6g %s\n', ...
    quad_geom.center(1), quad_geom.center(1)*angleDisplayFactor, angleLabel);
fprintf('Stationary centre O = %.6g rad = %.6g %s\n', ...
    quad_geom.center(2), quad_geom.center(2)*angleDisplayFactor, angleLabel);
fprintf('Quadratic matrix eigenvalues:\n');
disp(quad_geom.eigenvalues);
fprintf('Quadratic principal-axis angle = %.6g deg\n', rad2deg(quad_geom.rotationAngle));

%% ---------------- PLOTS ----------------

if makePlots

    %% Figure 1: Full quadratic response surface
    figure('Name','3D response surface','Color','w');
    hold on; box on; grid on;

    scatter3(A_raw, O_raw, TI, 60, TI, 'filled');

    nGrid = 90;
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
    title('Full quadratic response surface');
    view(135, 25);
    colorbar;

    %% Figure 2: Candidate physical collapses
    figure('Name','Physical scalar collapses','Color','w');
    tiledlayout(2,4, 'Padding','compact', 'TileSpacing','compact');

    plotCollapseScaled(chi_rms, TI, fit_rms_power, angleDisplayFactor, ...
        ['\chi_{RMS} [' angleLabel ']'], 'RMS angle');

    plotCollapseScaled(chi_endpoint_rms, TI, fit_endpoint_power, angleDisplayFactor, ...
        ['\chi_{endpoint} [' angleLabel ']'], 'Endpoint RMS');

    plotCollapseScaled(chi_mean_abs, TI, fit_mean_abs_power, angleDisplayFactor, ...
        ['<|\theta|> [' angleLabel ']'], 'Mean absolute angle');

    plotCollapseScaled(chi_peak_abs, TI, fit_peak_abs_power, angleDisplayFactor, ...
        ['max |\theta| [' angleLabel ']'], 'Peak absolute angle');

    plotCollapseScaled(chi_upper_abs, TI, fit_upper_abs_power, angleDisplayFactor, ...
        ['|\theta_{max}| [' angleLabel ']'], 'Upper endpoint magnitude');

    plotCollapseScaled(chi_block_rms, TI, fit_block_rms_power, 1, ...
        'B_{RMS}', 'Projected blockage RMS');

    plotCollapseScaled(chi_block_mean_abs, TI, fit_block_mean_power, 1, ...
        '<|sin(\theta)|>', 'Projected blockage mean');

    plotCollapseScaled(chi_block_peak, TI, fit_block_peak_power, 1, ...
        'max |sin(\theta)|', 'Projected blockage peak');

    %% Figure 3: Data-driven collapses
    figure('Name','Data-driven collapses','Color','w');
    tiledlayout(2,2, 'Padding','compact', 'TileSpacing','compact');

    chi_linear = fit_linear_combo_power.chi(A, O);
    plotCollapseScaled(chi_linear, TI, fit_linear_combo_power, angleDisplayFactor, ...
        ['|O + \lambda A| [' angleLabel ']'], 'Linear-combo collapse');

    chi_shifted = fit_shifted_linear_power.chi(A, O);
    plotCollapseScaled(chi_shifted, TI, fit_shifted_linear_power, angleDisplayFactor, ...
        ['|b + O + \lambda A| [' angleLabel ']'], 'Shifted linear-combo collapse');

    chi_weighted_peak = fit_weighted_peak_power.chi(A, O);
    plotCollapseScaled(chi_weighted_peak, TI, fit_weighted_peak_power, angleDisplayFactor, ...
        ['|O| + \lambda|A| [' angleLabel ']'], 'Weighted peak collapse');

    chi_ellipse = fit_ellipse_power.chi(A, O);
    plotCollapseScaled(chi_ellipse, TI, fit_ellipse_power, angleDisplayFactor, ...
        ['\chi_{ellipse} [' angleLabel ']'], 'Elliptic collapse');

    %% Figure 4: Best models, measured vs predicted
    [~, idxRMSE] = sort(metrics.RMSE, 'ascend');
    nShow = min(6, numel(idxRMSE));

    figure('Name','Measured vs predicted: best models','Color','w');
    hold on; box on; grid on;

    for jj = 1:nShow
        ii = idxRMSE(jj);
        plot(TI, predMat(:,ii), 'o', ...
            'MarkerSize', 7, ...
            'DisplayName', modelNames(ii));
    end

    minVal = min([TI; predMat(:)]);
    maxVal = max([TI; predMat(:)]);
    plot([minVal maxVal], [minVal maxVal], 'k--', ...
        'LineWidth', 1.5, ...
        'DisplayName','Perfect prediction');

    xlabel('Measured TI');
    ylabel('Predicted TI');
    title('Measured vs predicted: best models by RMSE');
    legend('Location','best');
    axis equal;
    xlim([minVal maxVal]);
    ylim([minVal maxVal]);

    %% Figure 5: Residuals for best single-parameter model
    bestIdx = idxRMSE(1);
    bestResidual = TI - predMat(:,bestIdx);

    figure('Name','Residual diagnostics for best model','Color','w');
    tiledlayout(2,2, 'Padding','compact', 'TileSpacing','compact');

    residualPlot(A_raw, bestResidual, ...
        ['Amplitude [' angleLabel ']'], ...
        ['Residuals: ' char(modelNames(bestIdx))]);

    residualPlot(O_raw, bestResidual, ...
        ['Offset [' angleLabel ']'], ...
        ['Residuals: ' char(modelNames(bestIdx))]);

    residualPlot(TI, bestResidual, ...
        'Measured TI', ...
        ['Residuals: ' char(modelNames(bestIdx))]);

    residualPlot(predMat(:,bestIdx), bestResidual, ...
        'Predicted TI', ...
        ['Residuals: ' char(modelNames(bestIdx))]);

    %% Figure 6: Contours for selected reduced models
    figure('Name','Reduced-model TI contours','Color','w');
    tiledlayout(2,3, 'Padding','compact', 'TileSpacing','compact');

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_peak_abs_power.predict(cyclePeakAbs(Aq, Oq, phi)), ...
        'Peak absolute angle model', angleLabel);

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_linear_combo_power.predict(Aq, Oq), ...
        'Linear-combo model', angleLabel);

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_shifted_linear_power.predict(Aq, Oq), ...
        'Shifted linear-combo model', angleLabel);

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_weighted_peak_power.predict(Aq, Oq), ...
        'Weighted peak model', angleLabel);

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_ellipse_power.predict(Aq, Oq), ...
        'Elliptic model', angleLabel);

    contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, ...
        @(Aq,Oq) fit_surface_quad.predict(Aq, Oq), ...
        'Full quadratic surface', angleLabel);
end

%% ========================================================================
%% LOCAL FUNCTIONS
%% ========================================================================

function fit = fitScalarPower(x, y)
    x = max(x(:), 0);
    y = y(:);

    xMax = max(x);
    yMin = min(y);
    yRange = max(y) - min(y);

    if xMax <= 0
        error('Scalar parameter has no positive values.');
    end

    TI0_0 = yMin;
    C0    = yRange / max(xMax, eps);
    n0    = 1;

    q0 = [TI0_0, C0, log(n0)];

    obj = @(q) sum((y - scalarPowerModel(q, x)).^2);

    opts = optimset( ...
        'Display','off', ...
        'MaxFunEvals', 8e4, ...
        'MaxIter', 8e4);

    q = fminsearch(obj, q0, opts);

    fit.TI0 = q(1);
    fit.C   = q(2);
    fit.n   = exp(q(3));
    fit.nParams = 3;
    fit.predict = @(xq) reshape( ...
        fit.TI0 + fit.C .* max(xq(:),0).^fit.n, size(xq));
    fit.predictChi = fit.predict;
end

function yhat = scalarPowerModel(q, x)
    TI0 = q(1);
    C   = q(2);
    n   = exp(q(3));

    yhat = TI0 + C .* max(x,0).^n;

    if any(~isfinite(yhat))
        yhat = inf(size(x));
    end
end

function fit = fitScalarQuadratic(x, y)
    x = x(:);
    y = y(:);

    Xmat = [ones(size(x)), x, x.^2];
    coeffs = Xmat \ y;

    fit.coeffs = coeffs;
    fit.nParams = 3;
    fit.predict = @(xq) reshape( ...
        [ones(numel(xq),1), xq(:), xq(:).^2] * coeffs, size(xq));
    fit.predictChi = fit.predict;
end

function fit = fitLinearComboPower(A, O, y)
    A = A(:);
    O = O(:);
    y = y(:);

    lambdaStarts = [-3 -2 -1 -0.5 0 0.5 1 2 3];

    bestSSE = inf;
    bestQ = [];

    for lambda0 = lambdaStarts
        chi0 = abs(O + lambda0*A);
        C0 = (max(y)-min(y)) / max(max(chi0), eps);
        q0 = [min(y), C0, log(1), lambda0];

        obj = @(q) sum((y - linearComboPowerModel(q, A, O)).^2);

        opts = optimset( ...
            'Display','off', ...
            'MaxFunEvals', 8e4, ...
            'MaxIter', 8e4);

        q = fminsearch(obj, q0, opts);
        SSE = obj(q);

        if SSE < bestSSE
            bestSSE = SSE;
            bestQ = q;
        end
    end

    fit.TI0 = bestQ(1);
    fit.C = bestQ(2);
    fit.n = exp(bestQ(3));
    fit.lambda = bestQ(4);
    fit.nParams = 4;

    fit.chi = @(Aq,Oq) abs(Oq + fit.lambda.*Aq);
    fit.predictChi = @(chiq) fit.TI0 + fit.C .* max(chiq,0).^fit.n;
    fit.predict = @(Aq,Oq) reshape( ...
        fit.predictChi(fit.chi(Aq(:),Oq(:))), size(Aq));
end

function yhat = linearComboPowerModel(q, A, O)
    TI0 = q(1);
    C = q(2);
    n = exp(q(3));
    lambda = q(4);

    chi = abs(O + lambda*A);
    yhat = TI0 + C.*chi.^n;

    if any(~isfinite(yhat))
        yhat = inf(size(A));
    end
end

function fit = fitShiftedLinearComboPower(A, O, y)
    A = A(:);
    O = O(:);
    y = y(:);

    lambdaStarts = [-2 -1 -0.5 0 0.5 1 2];
    biasStarts = [0, -median(O), -mean(O)];

    bestSSE = inf;
    bestQ = [];

    for lambda0 = lambdaStarts
        for bias0 = biasStarts
            chi0 = abs(bias0 + O + lambda0*A);
            C0 = (max(y)-min(y)) / max(max(chi0), eps);
            q0 = [min(y), C0, log(1), lambda0, bias0];

            obj = @(q) sum((y - shiftedLinearComboPowerModel(q, A, O)).^2) ...
                + centrePenalty(q(5), min([A;O]), max([A;O]));

            opts = optimset( ...
                'Display','off', ...
                'MaxFunEvals', 1e5, ...
                'MaxIter', 1e5);

            q = fminsearch(obj, q0, opts);
            SSE = sum((y - shiftedLinearComboPowerModel(q, A, O)).^2);

            if SSE < bestSSE
                bestSSE = SSE;
                bestQ = q;
            end
        end
    end

    fit.TI0 = bestQ(1);
    fit.C = bestQ(2);
    fit.n = exp(bestQ(3));
    fit.lambda = bestQ(4);
    fit.bias = bestQ(5);
    fit.nParams = 5;

    fit.chi = @(Aq,Oq) abs(fit.bias + Oq + fit.lambda.*Aq);
    fit.predictChi = @(chiq) fit.TI0 + fit.C .* max(chiq,0).^fit.n;
    fit.predict = @(Aq,Oq) reshape( ...
        fit.predictChi(fit.chi(Aq(:),Oq(:))), size(Aq));
end

function yhat = shiftedLinearComboPowerModel(q, A, O)
    TI0 = q(1);
    C = q(2);
    n = exp(q(3));
    lambda = q(4);
    bias = q(5);

    chi = abs(bias + O + lambda*A);
    yhat = TI0 + C.*chi.^n;

    if any(~isfinite(yhat))
        yhat = inf(size(A));
    end
end

function fit = fitWeightedPeakPower(A, O, y)
    A = A(:);
    O = O(:);
    y = y(:);

    lambdaStarts = [0.25 0.5 1 2 4];

    bestSSE = inf;
    bestQ = [];

    for lambda0 = lambdaStarts
        chi0 = abs(O) + lambda0*abs(A);
        C0 = (max(y)-min(y)) / max(max(chi0), eps);
        q0 = [min(y), C0, log(1), log(lambda0)];

        obj = @(q) sum((y - weightedPeakPowerModel(q, A, O)).^2);

        opts = optimset( ...
            'Display','off', ...
            'MaxFunEvals', 8e4, ...
            'MaxIter', 8e4);

        q = fminsearch(obj, q0, opts);
        SSE = obj(q);

        if SSE < bestSSE
            bestSSE = SSE;
            bestQ = q;
        end
    end

    fit.TI0 = bestQ(1);
    fit.C = bestQ(2);
    fit.n = exp(bestQ(3));
    fit.lambda = exp(bestQ(4));
    fit.nParams = 4;

    fit.chi = @(Aq,Oq) abs(Oq) + fit.lambda.*abs(Aq);
    fit.predictChi = @(chiq) fit.TI0 + fit.C .* max(chiq,0).^fit.n;
    fit.predict = @(Aq,Oq) reshape( ...
        fit.predictChi(fit.chi(Aq(:),Oq(:))), size(Aq));
end

function yhat = weightedPeakPowerModel(q, A, O)
    TI0 = q(1);
    C = q(2);
    n = exp(q(3));
    lambda = exp(q(4));

    chi = abs(O) + lambda*abs(A);
    yhat = TI0 + C.*chi.^n;

    if any(~isfinite(yhat))
        yhat = inf(size(A));
    end
end

function fit = fitEllipticPower(A, O, y, useCentre)
    A = A(:);
    O = O(:);
    y = y(:);

    [~, minIdx] = min(y);

    alphaStarts = [-2 0 2];
    betaStarts  = [-pi/4 0 pi/4];
    centreStarts = [ ...
        0, 0; ...
        A(minIdx), O(minIdx); ...
        mean(A), mean(O)];

    if ~useCentre
        centreStarts = [0, 0];
    end

    bestSSE = inf;
    bestQ = [];

    for alpha0 = alphaStarts
        for beta0 = betaStarts
            for cc = 1:size(centreStarts,1)

                cA0 = centreStarts(cc,1);
                cO0 = centreStarts(cc,2);

                [W0, ~, ~] = ellipseMatrixFromParams(alpha0, beta0);
                chi0 = sqrt(max( ...
                    W0(1,1)*(A-cA0).^2 + ...
                    2*W0(1,2)*(A-cA0).*(O-cO0) + ...
                    W0(2,2)*(O-cO0).^2, 0));

                C0 = (max(y)-min(y)) / max(max(chi0), eps);

                if useCentre
                    q0 = [min(y), C0, log(1), alpha0, beta0, cA0, cO0];
                else
                    q0 = [min(y), C0, log(1), alpha0, beta0];
                end

                obj = @(q) sum((y - ellipticPowerModel(q, A, O, useCentre)).^2) ...
                    + ellipseCentrePenalty(q, A, O, useCentre);

                opts = optimset( ...
                    'Display','off', ...
                    'MaxFunEvals', 1.5e5, ...
                    'MaxIter', 1.5e5);

                q = fminsearch(obj, q0, opts);
                SSE = sum((y - ellipticPowerModel(q, A, O, useCentre)).^2);

                if SSE < bestSSE
                    bestSSE = SSE;
                    bestQ = q;
                end
            end
        end
    end

    [W, ~, ~] = ellipseMatrixFromParams(bestQ(4), bestQ(5));

    fit.TI0 = bestQ(1);
    fit.C = bestQ(2);
    fit.n = exp(bestQ(3));
    fit.W = W;
    fit.nParams = 5 + 2*useCentre;

    if useCentre
        fit.cA = bestQ(6);
        fit.cO = bestQ(7);
    else
        fit.cA = 0;
        fit.cO = 0;
    end

    fit.chi = @(Aq,Oq) sqrt(max( ...
        W(1,1).*(Aq-fit.cA).^2 + ...
        2*W(1,2).*(Aq-fit.cA).*(Oq-fit.cO) + ...
        W(2,2).*(Oq-fit.cO).^2, 0));

    fit.predictChi = @(chiq) fit.TI0 + fit.C .* max(chiq,0).^fit.n;

    fit.predict = @(Aq,Oq) reshape( ...
        fit.predictChi(fit.chi(Aq(:),Oq(:))), size(Aq));
end

function yhat = ellipticPowerModel(q, A, O, useCentre)
    TI0 = q(1);
    C = q(2);
    n = exp(q(3));

    [W, ~, ~] = ellipseMatrixFromParams(q(4), q(5));

    if useCentre
        cA = q(6);
        cO = q(7);
    else
        cA = 0;
        cO = 0;
    end

    chi2 = ...
        W(1,1).*(A-cA).^2 + ...
        2*W(1,2).*(A-cA).*(O-cO) + ...
        W(2,2).*(O-cO).^2;

    chi = sqrt(max(chi2, 0));
    yhat = TI0 + C.*chi.^n;

    if any(~isfinite(yhat))
        yhat = inf(size(A));
    end
end

function [W, weights, beta] = ellipseMatrixFromParams(alpha, beta)
    % Positive eigenvalues with trace(W)=1.
    w1 = 1 / (1 + exp(-alpha));
    w2 = 1 - w1;

    weights = [w1, w2];

    R = [cos(beta), -sin(beta); sin(beta), cos(beta)];
    W = R * diag(weights) * R.';
end

function p = ellipseCentrePenalty(q, A, O, useCentre)
    p = 0;

    if ~useCentre
        return;
    end

    cA = q(6);
    cO = q(7);

    Amin = min(A); Amax = max(A); Ar = max(Amax-Amin, eps);
    Omin = min(O); Omax = max(O); Or = max(Omax-Omin, eps);

    A_low = Amin - 0.75*Ar;
    A_high = Amax + 0.75*Ar;
    O_low = Omin - 0.75*Or;
    O_high = Omax + 0.75*Or;

    if cA < A_low
        p = p + 1e6*(A_low-cA)^2;
    elseif cA > A_high
        p = p + 1e6*(cA-A_high)^2;
    end

    if cO < O_low
        p = p + 1e6*(O_low-cO)^2;
    elseif cO > O_high
        p = p + 1e6*(cO-O_high)^2;
    end
end

function p = centrePenalty(c, xmin, xmax)
    xr = max(xmax-xmin, eps);
    low = xmin - xr;
    high = xmax + xr;

    p = 0;

    if c < low
        p = 1e6*(low-c)^2;
    elseif c > high
        p = 1e6*(c-high)^2;
    end
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

function geom = quadraticGeometry(coeffs)
    c1 = coeffs(2);
    c2 = coeffs(3);
    c3 = coeffs(4);
    c4 = coeffs(5);
    c5 = coeffs(6);

    b = [c1; c2];
    Q = [c3, c5/2; c5/2, c4];

    if rcond(Q) > 1e-10
        centre = -0.5 * (Q \ b);
    else
        centre = [NaN; NaN];
    end

    [V,D] = eig(Q);
    eigVals = diag(D);

    [eigValsSorted, idx] = sort(eigVals, 'descend');
    V = V(:,idx);

    rotationAngle = atan2(V(2,1), V(1,1));

    geom.Q = Q;
    geom.center = centre;
    geom.eigenvalues = eigValsSorted;
    geom.eigenvectors = V;
    geom.rotationAngle = rotationAngle;
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

    SSE_for_AIC = max(SSE, realmin);
    AIC = n*log(SSE_for_AIC/n) + 2*k;

    if n > k + 1
        AICc = AIC + (2*k*(k+1))/(n-k-1);
    else
        AICc = NaN;
    end

    T = table(string(modelName), R2, RMSE, MAE, AICc, k, ...
        'VariableNames', {'Model','R2','RMSE','MAE','AICc','NumParams'});
end

function plotCollapseScaled(xFit, y, fit, displayFactor, xlab, ttl)
    % xFit is the variable used for fitting/prediction.
    % xPlot = xFit * displayFactor is only for display.
    %
    % Example:
    %   xFit in radians, displayFactor = 180/pi
    %   xPlot in degrees
    %
    % For nondimensional blockage variables, use displayFactor = 1.

    nexttile; hold on; box on; grid on;

    xFit = xFit(:);
    y = y(:);

    xPlot = xFit * displayFactor;

    scatter(xPlot, y, 45, 'filled');

    xFitLine = linspace(min(xFit), max(xFit), 400).';
    xPlotLine = xFitLine * displayFactor;

    % Correct: predict using xFitLine, not xPlotLine.
    if isfield(fit, 'predictChi')
        yFitLine = fit.predictChi(xFitLine);
    else
        yFitLine = fit.predict(xFitLine);
    end

    plot(xPlotLine, yFitLine, 'LineWidth', 2);

    xlabel(xlab);
    ylabel('Average TI');
    title(ttl);
end

function idx = sortIndex(x)
    [~, idx] = sort(x);
end

function residualPlot(x, residuals, xlab, ttl)
    nexttile; hold on; box on; grid on;
    scatter(x, residuals, 45, 'filled');
    yline(0, 'k--', 'LineWidth', 1.2);
    xlabel(xlab);
    ylabel('Residual');
    title(ttl);
end

function contourReducedModel(AA_raw, OO_raw, AA, OO, A_raw, O_raw, TI, predFcn, ttl, angleLabel)
    nexttile; hold on; box on;

    TI_grid = predFcn(AA, OO);

    contourf(AA_raw, OO_raw, TI_grid, 20, 'LineColor','none');
    scatter(A_raw, O_raw, 35, TI, 'filled', 'MarkerEdgeColor','k');

    xlabel(['Amplitude [' angleLabel ']']);
    ylabel(['Offset [' angleLabel ']']);
    title(ttl);
    colorbar;
end

function ellipseInfo(W, labelText)
    [V,D] = eig(W);
    eigVals = diag(D);

    [eigValsSorted, idx] = sort(eigVals, 'descend');
    V = V(:,idx);

    angle = atan2(V(2,1), V(1,1));

    fprintf('\n%s geometry:\n', labelText);
    fprintf('Eigenvalues: %.6g, %.6g\n', eigValsSorted(1), eigValsSorted(2));
    fprintf('Principal-axis angle = %.6g deg\n', rad2deg(angle));
    fprintf('Principal direction vector = [%.6g, %.6g]\n', V(1,1), V(2,1));
end

function chi = cyclePeakAbs(Aq, Oq, phi)
    % Computes chi = max_phi |O + A*sin(phi)| for matrix/grid inputs.

    originalSize = size(Aq);

    Acol = Aq(:);
    Ocol = Oq(:);

    theta = Ocol + Acol .* sin(phi);   % numel(Aq) x nPhi
    chiCol = max(abs(theta), [], 2);

    chi = reshape(chiCol, originalSize);
end
