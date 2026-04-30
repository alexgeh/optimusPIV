%% Evaluate quality of parameter space exploration - streamlined/shared GP version
clear

load("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20260429_ATG_highFreq_actLearn_4\actLearnDB.mat")

inputNames  = {'actuation.alpha', 'actuation.relBeta', ...
    'actuation.ampgrad', 'actuation.offsetgrad'};
outputNames = {'metrics.TI_mean', 'metrics.CV_U', 'metrics.CV_TI', ...
    'metrics.aniso_mean', 'metrics.dUdy_slope', 'metrics.dTIdy_slope'};

inputRanges = [
    0, 59.5
    0, 1
   -45, 45
   -45, 45
];

fprintf('Extracting data from database...\n');
X = actLearn_extractMatrixFromDB(optDB, inputNames);
Y = actLearn_extractMatrixFromDB(optDB, outputNames);

validRows = all(isfinite(X),2) & all(isfinite(Y),2);
X = X(validRows,:);
Y = Y(validRows,:);

% Normalise to [0,1]. Use the same Xn for all GP diagnostics below.
Xn = NaN(size(X));
for k = 1:numel(inputNames)
    Xn(:,k) = (X(:,k) - inputRanges(k,1)) ./ diff(inputRanges(k,:));
end

%% Basic input coverage
disp(array2table([min(Xn); max(Xn); range(Xn)], ...
    'VariableNames', makeSafeNames(inputNames), ...
    'RowNames', {'min','max','range'}));

D = pdist(Xn);
fprintf('Minimum normalised pairwise distance: %.3f\n', min(D));
fprintf('Median normalised pairwise distance:  %.3f\n', median(D));
fprintf('Maximum normalised pairwise distance: %.3f\n', max(D));

figure;
plotmatrix(Xn);
sgtitle('Normalised sampled input space');

%% Output range statistics
T = array2table([min(Y); max(Y); mean(Y); std(Y); range(Y)], ...
    'VariableNames', makeSafeNames(outputNames), ...
    'RowNames', {'min','max','mean','std','range'});
disp(T);

%% Shared GP training + diagnostics
% Use the same training routine/kernel as the active-learning experiment.
[models, gpStats] = actLearn_trainOutputModels(Xn, Y, outputNames, ...
    'KernelFunction', 'ardmatern52', ...
    'Standardize', true, ...
    'MinTrain', 8, ...
    'DoLOO', true);

disp(gpStats.summaryTable);

fprintf('\nARD length scales, using normalised inputs:\n');
disp(array2table(gpStats.lengthScales, ...
    'VariableNames', makeSafeNames(inputNames), ...
    'RowNames', makeSafeNames(outputNames)));

%% Measured score history, if available
if isfield(optDB, 'J')
    J = [optDB(validRows).J];
    figure;
    plot(J, 'o-'); hold on;
    plot(cummin(J), 'k-', 'LineWidth', 2);
    xlabel('Iteration');
    ylabel('Measured objective J');
    legend('J','Best so far');
    grid on;
    title('Measured objective progress');
else
    J = [];
end

%% Physical trend scatter plots
for m = 1:numel(outputNames)
    figure;
    tiledlayout(2,2);
    for k = 1:numel(inputNames)
        nexttile;
        scatter(X(:,k), Y(:,m), 60, 'filled');
        xlabel(inputNames{k}, 'Interpreter','none');
        ylabel(outputNames{m}, 'Interpreter','none');
        grid on;
    end
    sgtitle(outputNames{m}, 'Interpreter','none');
end

%% Exploration diagnostics from the same GP models
uncDiag = diagnoseUncertaintyContributions_local(models, gpStats, inputNames, outputNames, 10000);
disp(uncDiag.meanContributionTable);
disp(uncDiag.maxAcquisitionContributionTable);

gpHist = diagnoseGPHistory_local(Xn, Y, outputNames, ...
    'KernelFunction', gpStats.kernelFunction, ...
    'StartAt', 8, ...
    'Step', 2, ...
    'NCandidates', 3000);

%% Conditional response slices
plotGPSlices2D_local(models, X, Y, inputNames, outputNames, inputRanges, ...
    'actuation.alpha', 'actuation.relBeta', 'median');

plotGPSlices2D_local(models, X, Y, inputNames, outputNames, inputRanges, ...
    'actuation.ampgrad', 'actuation.offsetgrad', 'median');


%% Local analysis-only helpers ------------------------------------------------
function uncDiag = diagnoseUncertaintyContributions_local(models, gpStats, inputNames, outputNames, nCandidates)
    nInputs = numel(inputNames);
    nOutputs = numel(outputNames);
    Xcand = rand(nCandidates, nInputs);

    sigmaNorm = NaN(nCandidates, nOutputs);
    for m = 1:nOutputs
        if ~models(m).isTrained
            continue
        end
        [~, sd] = predict(models(m).gp, Xcand);
        sigmaNorm(:,m) = models(m).exploreWeight .* sd ./ max(models(m).yScale, eps);
    end

    scoreSquared = sigmaNorm.^2;
    denom = sum(scoreSquared, 2, 'omitnan');
    contribution = scoreSquared ./ denom;
    exploreScore = sqrt(mean(scoreSquared, 2, 'omitnan'));
    [~, bestIdx] = max(exploreScore);

    uncDiag = struct();
    uncDiag.meanContribution = mean(contribution, 1, 'omitnan');
    uncDiag.maxAcqContribution = contribution(bestIdx,:);
    uncDiag.bestXn = Xcand(bestIdx,:);
    uncDiag.meanContributionTable = array2table(uncDiag.meanContribution, ...
        'VariableNames', makeSafeNames(outputNames));
    uncDiag.maxAcquisitionContributionTable = array2table(uncDiag.maxAcqContribution, ...
        'VariableNames', makeSafeNames(outputNames));

    figure('Name','Mean uncertainty contribution by output');
    bar(uncDiag.meanContribution);
    set(gca, 'XTick', 1:numel(outputNames), 'XTickLabel', outputNames, 'XTickLabelRotation', 45);
    ylabel('Mean fractional contribution');
    title('Mean contribution to exploration uncertainty');
    grid on;
end

function gpHist = diagnoseGPHistory_local(Xn, Y, outputNames, varargin)
    p = inputParser;
    addParameter(p, 'KernelFunction', 'ardmatern52');
    addParameter(p, 'StartAt', 8);
    addParameter(p, 'Step', 2);
    addParameter(p, 'NCandidates', 3000);
    parse(p, varargin{:});

    nPts = size(Xn,1);
    nInputs = size(Xn,2);
    nOutputs = size(Y,2);
    nTrainList = p.Results.StartAt:p.Results.Step:nPts;
    if nTrainList(end) ~= nPts
        nTrainList = [nTrainList, nPts];
    end
    Xcand = rand(p.Results.NCandidates, nInputs);

    meanUnc = NaN(numel(nTrainList), nOutputs);
    maxUnc = NaN(numel(nTrainList), nOutputs);
    lenScale = NaN(numel(nTrainList), nOutputs, nInputs);

    for ii = 1:numel(nTrainList)
        n = nTrainList(ii);
        fprintf('GP history: n = %d / %d\n', n, nPts);
        [mods, stats] = actLearn_trainOutputModels(Xn(1:n,:), Y(1:n,:), outputNames, ...
            'KernelFunction', p.Results.KernelFunction, ...
            'Standardize', true, ...
            'MinTrain', 8, ...
            'DoLOO', false);

        lenScale(ii,:,:) = stats.lengthScales;
        for m = 1:nOutputs
            if ~mods(m).isTrained
                continue
            end
            [~, sd] = predict(mods(m).gp, Xcand);
            sdNorm = sd ./ max(mods(m).yScale, eps);
            meanUnc(ii,m) = mean(sdNorm, 'omitnan');
            maxUnc(ii,m) = max(sdNorm, [], 'omitnan');
        end
    end

    gpHist = struct('nTrain', nTrainList(:), 'meanUncertainty', meanUnc, ...
        'maxUncertainty', maxUnc, 'lengthScales', lenScale);

    figure('Name','GP history: mean normalised uncertainty');
    plot(gpHist.nTrain, gpHist.meanUncertainty, 'o-', 'LineWidth', 1.2);
    xlabel('Number of training points');
    ylabel('Mean predictive sd / output scale');
    legend(outputNames, 'Interpreter','none', 'Location','best');
    title('Mean GP uncertainty over candidate space');
    grid on;

    figure('Name','GP history: max normalised uncertainty');
    plot(gpHist.nTrain, gpHist.maxUncertainty, 'o-', 'LineWidth', 1.2);
    xlabel('Number of training points');
    ylabel('Max predictive sd / output scale');
    legend(outputNames, 'Interpreter','none', 'Location','best');
    title('Max GP uncertainty over candidate space');
    grid on;
end

function plotGPSlices2D_local(models, X, Y, inputNames, outputNames, inputRanges, xName, yName, fixedMode)
    ix = find(strcmp(inputNames, xName), 1);
    iy = find(strcmp(inputNames, yName), 1);
    if isempty(ix) || isempty(iy)
        error('Requested slice inputs were not found.');
    end

    switch lower(fixedMode)
        case 'median'
            xFixed = median(X, 1, 'omitnan');
        case 'mean'
            xFixed = mean(X, 1, 'omitnan');
        case 'center'
            xFixed = mean(inputRanges, 2)';
        otherwise
            error('Unknown fixedMode: %s', fixedMode);
    end

    nGrid = 60;
    xv = linspace(inputRanges(ix,1), inputRanges(ix,2), nGrid);
    yv = linspace(inputRanges(iy,1), inputRanges(iy,2), nGrid);
    [Xg, Yg] = meshgrid(xv, yv);

    Xq = repmat(xFixed, numel(Xg), 1);
    Xq(:,ix) = Xg(:);
    Xq(:,iy) = Yg(:);
    XqN = normaliseWithRanges_local(Xq, inputRanges);

    for m = 1:numel(outputNames)
        if ~models(m).isTrained
            continue
        end
        [mu, sd] = predict(models(m).gp, XqN);
        Mu = reshape(mu, nGrid, nGrid);
        Sd = reshape(sd, nGrid, nGrid);

        figure('Name',['GP slice: ', outputNames{m}]);
        tiledlayout(1,2);
        nexttile;
        surf(Xg, Yg, Mu, 'EdgeColor','none', 'FaceAlpha',0.85); hold on;
        scatter3(X(:,ix), X(:,iy), Y(:,m), 35, 'k', 'filled'); hold off;
        xlabel(xName, 'Interpreter','none'); ylabel(yName, 'Interpreter','none');
        zlabel(outputNames{m}, 'Interpreter','none');
        title(['Predicted mean: ', outputNames{m}], 'Interpreter','none');
        colorbar; grid on; view(-30,45);

        nexttile;
        surf(Xg, Yg, Sd, 'EdgeColor','none', 'FaceAlpha',0.85);
        xlabel(xName, 'Interpreter','none'); ylabel(yName, 'Interpreter','none');
        zlabel('Predictive sd'); title('Predictive uncertainty');
        colorbar; grid on; view(-30,45);
    end
end

function Xn = normaliseWithRanges_local(X, inputRanges)
    Xn = NaN(size(X));
    for k = 1:size(X,2)
        Xn(:,k) = (X(:,k) - inputRanges(k,1)) ./ diff(inputRanges(k,:));
    end
end

function safeNames = makeSafeNames(names)
    safeNames = matlab.lang.makeValidName(strrep(string(names), '.', '_'));
    safeNames = cellstr(safeNames);
end
