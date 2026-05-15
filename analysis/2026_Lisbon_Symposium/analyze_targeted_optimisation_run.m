%% Analyse targeted active-learning optimisation run
% This script analyses ONLY the latest caseDir in actLearnDB.mat.
% It recomputes measured target scores, tolerance violations, penalty scores,
% convergence behaviour, and Pareto candidates among points that satisfy the
% target tolerances.
%
% Edit the USER SETTINGS block below for your current target case.

clear; close all; clc

%% USER SETTINGS

dbPath = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20260511_ATG_highFreq_actLearn_13\actLearnDB.mat";
% dbPath = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20260508_midRun_actLearnDB.mat";

% If true, automatically selects all entries with the same caseDir as
% the latest non-empty caseDir in optDB. If false, set manualCaseDir below.
useLatestCaseDir = true;
manualCaseDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\YOUR_CASE_FOLDER";

csvDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\2026_LisbonSymposium\";

% Target quantities: these are soft constraints.
% tol is in physical metric units. Do not set it smaller than repeatability.
targetDefs = struct([]);

targetDefs(end+1).name   = 'TI_mean';
targetDefs(end).key      = 'metrics.TI_mean';
targetDefs(end).target   = 0.10;
% targetDefs(end).tol      = 0.05 * abs(targetDefs(end).target);  % 5% of TI target
targetDefs(end).tol      = 0.01;  % 5% of TI target
targetDefs(end).label    = 'TI_{mean}';

targetDefs(end+1).name   = 'dTIdy_slope';
targetDefs(end).key      = 'metrics.dTIdy_slope';
targetDefs(end).target   = 0;
% targetDefs(end).tol      = 0.05 * abs(targetDefs(end).target);  % tune if repeatability is larger
% targetDefs(end).target   = 0;
targetDefs(end).tol      = 0.03;  % tune if repeatability is larger
targetDefs(end).label    = 'dTI/dy slope';

targetDefs(end+1).name   = 'dUdy_slope';
targetDefs(end).key      = 'metrics.dUdy_slope';
targetDefs(end).target   = 0.00;
targetDefs(end).tol      = 0.30;                                % absolute tolerance for zero target
% targetDefs(end).target   = 2.00;
% targetDefs(end).tol      = 0.30;                                % absolute tolerance for zero target
targetDefs(end).label    = 'dU/dy slope';

% Lower-is-better quantities, used only after/near target feasibility.
penaltyDefs = struct([]);

penaltyDefs(end+1).name = 'CV_U';
penaltyDefs(end).key    = 'metrics.CV_U';
penaltyDefs(end).label  = 'CV_U';

penaltyDefs(end+1).name = 'CV_TI';
penaltyDefs(end).key    = 'metrics.CV_TI';
penaltyDefs(end).label  = 'CV_{TI}';

penaltyDefs(end+1).name = 'aniso_mean';
penaltyDefs(end).key    = 'metrics.aniso_mean';
penaltyDefs(end).label  = 'anisotropy';

% Score settings. These should match targetCost.m if you want exact consistency.
outsidePenalty = 10;
gateSharpness  = 10;

% How to scale penalty metrics for dimensionless penaltyScore.
% Options: "allDB_robust", "latest_robust", "allDB_std", "latest_std"
penaltyScaleMode = "allDB_robust";

% Pareto options
requireAllTargetsWithinToleranceForPareto = true;

% Plot settings
nKeepRecent = inf;        % set to e.g. 80 if the run is very long
saveFigures = false;
figDir = "targeted_optimisation_analysis_figures";

%% LOAD DATABASE

fprintf('Loading database:\n%s\n', dbPath);
S = load(dbPath, 'optDB');
optDB = S.optDB;

if isempty(optDB)
    error('optDB is empty.');
end

caseDirs = getCaseDirs(optDB);

if useLatestCaseDir
    validCaseDir = caseDirs ~= "" & caseDirs ~= "caseDir_unknown";
    if ~any(validCaseDir)
        error('No valid caseDir entries found in optDB.');
    end

    latestIdx = find(validCaseDir, 1, 'last');
    selectedCaseDir = caseDirs(latestIdx);
else
    selectedCaseDir = string(manualCaseDir);
end

idxCase = find(caseDirs == selectedCaseDir);

if isempty(idxCase)
    error('No entries found for caseDir:\n%s', selectedCaseDir);
end

rec = optDB(idxCase);
n = numel(rec);
iter = (1:n)';

fprintf('\nSelected caseDir:\n%s\n', selectedCaseDir);
fprintf('Number of records in selected caseDir: %d\n', n);
fprintf('Global DB index range: %d to %d\n\n', idxCase(1), idxCase(end));

if ~isinf(nKeepRecent) && nKeepRecent < n
    keep = (n-nKeepRecent+1):n;
else
    keep = 1:n;
end

%% EXTRACT MEASURED TARGETS AND PENALTIES

Ytarget = extractKeys(rec, {targetDefs.key});
Ypenalty = extractKeys(rec, {penaltyDefs.key});

Ytarget_allDB = extractKeys(optDB, {targetDefs.key}); %#ok<NASGU>
Ypenalty_allDB = extractKeys(optDB, {penaltyDefs.key});

targetNames = {targetDefs.name}; %#ok<NASGU>
penaltyNames = {penaltyDefs.name}; %#ok<NASGU>
targetLabels = {targetDefs.label};
penaltyLabels = {penaltyDefs.label};

targetVals = [targetDefs.target];
targetTol  = [targetDefs.tol];

%% COMPUTE SCORES

errNorm = (Ytarget - targetVals) ./ max(targetTol, eps);
absErrNorm = abs(errNorm);

withinTargetEach = absErrNorm <= 1;
withinAllTargets = all(withinTargetEach, 2);

targetScore = sqrt(mean(errNorm.^2, 2, 'omitnan'));
targetViolation = sqrt(mean(max(absErrNorm - 1, 0).^2, 2, 'omitnan'));

penaltyScale = computePenaltyScale(Ypenalty, Ypenalty_allDB, penaltyScaleMode);
penaltyNorm = max(Ypenalty, 0) ./ max(penaltyScale, eps);
penaltyScore = sqrt(mean(penaltyNorm.^2, 2, 'omitnan'));

targetGate = 1 ./ (1 + exp(gateSharpness .* (targetScore - 1)));
totalCost = targetScore.^2 + outsidePenalty .* targetViolation.^2 + targetGate .* penaltyScore.^2;

bestTotalSoFar = cummin(totalCost);
bestTargetSoFar = cummin(targetScore);
bestPenaltyFeasibleSoFar = runningBestFeasible(penaltyScore, withinAllTargets);

%% PRINT SUMMARY

fprintf('Target tolerances:\n');
for k = 1:numel(targetDefs)
    fprintf('  %-14s target = %+g, tol = %g\n', targetDefs(k).name, targetDefs(k).target, targetDefs(k).tol);
end

fprintf('\nPenalty scales (%s):\n', penaltyScaleMode);
for k = 1:numel(penaltyDefs)
    fprintf('  %-14s scale = %g\n', penaltyDefs(k).name, penaltyScale(k));
end

fprintf('\nTolerance satisfaction in selected case:\n');
for k = 1:numel(targetDefs)
    fprintf('  %-14s within tolerance: %3d / %3d  (%.1f%%)\n', ...
        targetDefs(k).name, sum(withinTargetEach(:,k)), n, 100*mean(withinTargetEach(:,k)));
end
fprintf('  %-14s within tolerance: %3d / %3d  (%.1f%%)\n', ...
    'ALL TARGETS', sum(withinAllTargets), n, 100*mean(withinAllTargets));

[~, iBestTotal] = min(totalCost);
[~, iBestTarget] = min(targetScore);

if any(withinAllTargets)
    feasibleIdx = find(withinAllTargets);
    [~, j] = min(penaltyScore(feasibleIdx));
    iBestFeasiblePenalty = feasibleIdx(j);
else
    iBestFeasiblePenalty = NaN;
end

summaryRows = [];
summaryLabels = {};
summaryRows(end+1) = iBestTotal; summaryLabels{end+1} = 'best total cost';
summaryRows(end+1) = iBestTarget; summaryLabels{end+1} = 'best target score';
if isfinite(iBestFeasiblePenalty)
    summaryRows(end+1) = iBestFeasiblePenalty; summaryLabels{end+1} = 'best feasible penalty';
end

fprintf('\nSelected best candidates:\n');
for r = 1:numel(summaryRows)
    i = summaryRows(r);
    fprintf('\n%s: case iter %d, global DB idx %d\n', summaryLabels{r}, i, idxCase(i));
    fprintf('  totalCost = %.4g, targetScore = %.4g, targetViolation = %.4g, penaltyScore = %.4g\n', ...
        totalCost(i), targetScore(i), targetViolation(i), penaltyScore(i));
    for k = 1:numel(targetDefs)
        fprintf('  %-14s measured = %+g, target = %+g, norm.err = %+g\n', ...
            targetDefs(k).name, Ytarget(i,k), targetVals(k), errNorm(i,k));
    end
    for k = 1:numel(penaltyDefs)
        fprintf('  %-14s measured = %+g, norm.penalty = %+g\n', ...
            penaltyDefs(k).name, Ypenalty(i,k), penaltyNorm(i,k));
    end
end

%% BUILD RESULT TABLE

resultsTable = table();
resultsTable.caseIter = iter;
resultsTable.globalDBIdx = idxCase(:);
resultsTable.totalCost = totalCost;
resultsTable.targetScore = targetScore;
resultsTable.targetViolation = targetViolation;
resultsTable.penaltyScore = penaltyScore;
resultsTable.targetGate = targetGate;
resultsTable.withinAllTargets = withinAllTargets;

for k = 1:numel(targetDefs)
    resultsTable.(targetDefs(k).name) = Ytarget(:,k);
    resultsTable.([targetDefs(k).name '_normErr']) = errNorm(:,k);
    resultsTable.([targetDefs(k).name '_withinTol']) = withinTargetEach(:,k);
end

for k = 1:numel(penaltyDefs)
    resultsTable.(penaltyDefs(k).name) = Ypenalty(:,k);
    resultsTable.([penaltyDefs(k).name '_normPenalty']) = penaltyNorm(:,k);
end

fprintf('\nTop 10 candidates by total cost:\n');
sortedByCost = sortrows(resultsTable, 'totalCost', 'ascend');
disp(sortedByCost(1:min(10,height(sortedByCost)), :));

%% FIGURE 1: CONVERGENCE SUMMARY

figure('Name','Targeted optimisation convergence','Color','w');
tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(iter(keep), totalCost(keep), 'o-', 'DisplayName','measured total cost'); hold on;
plot(iter(keep), bestTotalSoFar(keep), 'k-', 'LineWidth',1.8, 'DisplayName','best so far');
xlabel('Iteration'); ylabel('Cost');
title('Measured total cost');
legend('Location','best'); grid on;

nexttile;
plot(iter(keep), targetScore(keep), 'o-', 'DisplayName','target score'); hold on;
plot(iter(keep), bestTargetSoFar(keep), 'k-', 'LineWidth',1.8, 'DisplayName','best target so far');
yline(1, '--', 'targetScore = 1', 'DisplayName','targetScore = 1');
xlabel('Iteration'); ylabel('Target score');
title('Target matching');
legend('Location','best'); grid on;

nexttile;
plot(iter(keep), targetViolation(keep), 'o-', 'DisplayName','target violation'); hold on;
yline(0, 'k--', 'DisplayName','no violation');
xlabel('Iteration'); ylabel('Violation score');
title('Distance outside tolerance band');
legend('Location','best'); grid on;

nexttile;
plot(iter(keep), penaltyScore(keep), 'o-', 'DisplayName','penalty score'); hold on;
plot(iter(keep), bestPenaltyFeasibleSoFar(keep), 'k-', 'LineWidth',1.8, 'DisplayName','best feasible penalty so far');
xlabel('Iteration'); ylabel('Penalty score');
title('CV/aniso penalty');
legend('Location','best'); grid on;

%% FIGURE 2: TARGET METRICS WITH TOLERANCE BANDS

figure('Name','Target metrics and tolerance bands','Color','w');
tiledlayout(numel(targetDefs),1, 'TileSpacing','compact', 'Padding','compact');

for k = 1:numel(targetDefs)
    nexttile;
    y = Ytarget(:,k);

    lo = targetVals(k) - targetTol(k);
    hi = targetVals(k) + targetTol(k);

    fill([iter(keep); flipud(iter(keep))], ...
         [lo*ones(numel(keep),1); hi*ones(numel(keep),1)], ...
         [0.85 0.95 1.0], 'EdgeColor','none', 'DisplayName','tolerance band');
    hold on;
    plot(iter(keep), y(keep), 'o-', 'DisplayName','measured');
    yline(targetVals(k), 'k-', 'LineWidth',1.5, 'DisplayName','target');
    xlabel('Iteration');
    ylabel(targetLabels{k}, 'Interpreter','none');
    title(sprintf('%s target tracking', targetLabels{k}), 'Interpreter','none');
    legend('Location','best'); grid on;
end

%% FIGURE 3: NORMALISED TARGET ERRORS

figure('Name','Normalised target errors','Color','w');
plot(iter(keep), absErrNorm(keep,:), 'o-', 'LineWidth',1.2); hold on;
yline(1, 'k--', 'Tolerance boundary');
xlabel('Iteration');
ylabel('|measured - target| / tolerance');
legend(targetLabels, 'Interpreter','none', 'Location','best');
title('Soft-constraint satisfaction by target');
grid on;

%% FIGURE 4: PENALTY METRICS

figure('Name','Penalty metrics','Color','w');
tiledlayout(1,2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
plot(iter(keep), Ypenalty(keep,:), 'o-', 'LineWidth',1.2);
xlabel('Iteration'); ylabel('Measured value');
legend(penaltyLabels, 'Interpreter','none', 'Location','best');
title('Raw penalty metrics');
grid on;

nexttile;
plot(iter(keep), penaltyNorm(keep,:), 'o-', 'LineWidth',1.2);
xlabel('Iteration'); ylabel('Metric / penalty scale');
legend(penaltyLabels, 'Interpreter','none', 'Location','best');
title('Normalised penalty metrics');
grid on;

%% FIGURE 5: TRADE-OFF PLOT TARGET VS PENALTY

figure('Name','Target-penalty tradeoff','Color','w');
scatter(targetScore, penaltyScore, 55, iter, 'filled'); hold on;
scatter(targetScore(withinAllTargets), penaltyScore(withinAllTargets), 90, ...
    'o', 'MarkerEdgeColor','k', 'LineWidth',1.4, 'DisplayName','within all tolerances');

xlabel('Target score');
ylabel('Penalty score');
title('Trade-off: target matching vs CV/aniso penalty');
cb = colorbar; ylabel(cb, 'Iteration');
grid on;
xline(1, 'k--', 'targetScore = 1');
legend('all candidates','within all tolerances', 'Location','best');

%% FIGURE 6: PARETO FRONT

if requireAllTargetsWithinToleranceForPareto
    paretoCandidateMask = withinAllTargets;
else
    paretoCandidateMask = true(n,1);
end

if any(paretoCandidateMask)
    idxP = find(paretoCandidateMask);
    objectives = penaltyNorm(idxP,:);   % minimise all penalty metrics
    pfLocal = paretoFrontMin(objectives);
    idxPareto = idxP(pfLocal);
    paretoTitle = 'Pareto front among candidates within all target tolerances';
else
    % Fallback: no strictly feasible candidates.
    % Show Pareto front in targetScore/penaltyScore space.
    idxP = (1:n)';
    objectives = [targetScore, penaltyScore];
    pfLocal = paretoFrontMin(objectives);
    idxPareto = idxP(pfLocal);
    paretoTitle = 'No fully feasible candidates: Pareto front of targetScore vs penaltyScore';
    warning('No candidates satisfy all target tolerances. Showing fallback Pareto front in targetScore/penaltyScore space.');
end

fprintf('\nPareto candidates:\n');
fprintf('  Number of candidate points considered: %d\n', numel(idxP));
fprintf('  Number of Pareto candidates: %d\n', numel(idxPareto));
disp(resultsTable(idxPareto,:));

figure('Name','Pareto visualisation','Color','w');

if any(paretoCandidateMask)
    if size(penaltyNorm,2) >= 3
        scatter3(penaltyNorm(paretoCandidateMask,1), penaltyNorm(paretoCandidateMask,2), penaltyNorm(paretoCandidateMask,3), ...
            45, iter(paretoCandidateMask), 'filled'); hold on;
        scatter3(penaltyNorm(idxPareto,1), penaltyNorm(idxPareto,2), penaltyNorm(idxPareto,3), ...
            130, 'r', 'p', 'filled', 'MarkerEdgeColor','k');
        xlabel([penaltyLabels{1} ' / scale'], 'Interpreter','none');
        ylabel([penaltyLabels{2} ' / scale'], 'Interpreter','none');
        zlabel([penaltyLabels{3} ' / scale'], 'Interpreter','none');
        grid on;
        title(paretoTitle, 'Interpreter','none');
        cb = colorbar; ylabel(cb, 'Iteration');
        legend('feasible candidates','Pareto candidates','Location','best');
        view(40,25);
    else
        scatter(penaltyNorm(paretoCandidateMask,1), penaltyNorm(paretoCandidateMask,2), ...
            45, iter(paretoCandidateMask), 'filled'); hold on;
        scatter(penaltyNorm(idxPareto,1), penaltyNorm(idxPareto,2), ...
            130, 'r', 'p', 'filled', 'MarkerEdgeColor','k');
        xlabel([penaltyLabels{1} ' / scale'], 'Interpreter','none');
        ylabel([penaltyLabels{2} ' / scale'], 'Interpreter','none');
        grid on;
        title(paretoTitle, 'Interpreter','none');
        cb = colorbar; ylabel(cb, 'Iteration');
        legend('feasible candidates','Pareto candidates','Location','best');
    end
else
    scatter(targetScore, penaltyScore, 45, iter, 'filled'); hold on;
    scatter(targetScore(idxPareto), penaltyScore(idxPareto), ...
        130, 'r', 'p', 'filled', 'MarkerEdgeColor','k');
    xlabel('Target score');
    ylabel('Penalty score');
    title(paretoTitle, 'Interpreter','none');
    cb = colorbar; ylabel(cb, 'Iteration');
    grid on;
    legend('all candidates','Pareto candidates','Location','best');
end

%% FIGURE 7: FEASIBILITY OVER RECENT ITERATIONS

windowSize = min(10, n);
feasRolling = movmean(double(withinAllTargets), [windowSize-1 0], 'omitnan');

figure('Name','Target feasibility over time','Color','w');
plot(iter, double(withinAllTargets), 'o-', 'DisplayName','all targets feasible'); hold on;
plot(iter, feasRolling, 'k-', 'LineWidth',2, 'DisplayName',sprintf('%d-run moving fraction', windowSize));
for k = 1:numel(targetDefs)
    plot(iter, movmean(double(withinTargetEach(:,k)), [windowSize-1 0], 'omitnan'), ...
        '--', 'DisplayName',[targetLabels{k} ' feasible']);
end
ylim([-0.05 1.05]);
xlabel('Iteration');
ylabel('Feasibility fraction / indicator');
title('Soft-constraint feasibility over time');
legend('Location','best', 'Interpreter','none');
grid on;

%% OPTIONAL SAVE

if saveFigures
    if ~isfolder(figDir)
        mkdir(figDir);
    end
    figs = findall(0, 'Type', 'figure');
    for i = 1:numel(figs)
        f = figs(i);
        fname = fullfile(figDir, sprintf('fig_%02d_%s.png', i, matlab.lang.makeValidName(f.Name)));
        exportgraphics(f, fname, 'Resolution', 200);
    end
    fprintf('\nSaved figures to: %s\n', figDir);
end


%% Feasibility sensitivity to tolerance multiplier
tolMultipliers = [1 1.5 2 3 5 10];
fprintf('\nFeasibility sensitivity to tolerance multiplier:\n');

for q = 1:numel(tolMultipliers)
    mult = tolMultipliers(q);

    withinMat = false(size(Ytarget));

    for j = 1:numel(targetDefs)
        tol_j = mult * targetDefs(j).tol;
        withinMat(:,j) = abs(Ytarget(:,j) - targetDefs(j).target) <= tol_j;
    end

    withinAll = all(withinMat, 2);

    fprintf('\nTolerance multiplier = %.2g\n', mult);

    for j = 1:numel(targetDefs)
        fprintf('  %-14s within tolerance: %3d / %3d  (%5.1f%%)\n', ...
            targetDefs(j).name, ...
            sum(withinMat(:,j)), ...
            numel(withinAll), ...
            100 * mean(withinMat(:,j)));
    end

    fprintf('  %-14s within tolerance: %3d / %3d  (%5.1f%%)\n', ...
        'ALL TARGETS', ...
        sum(withinAll), ...
        numel(withinAll), ...
        100 * mean(withinAll));
end


%% Identify the Best Case and Plot Profiles
% Use the best indices already calculated by the script

if isfinite(iBestFeasiblePenalty)
    bestIterIdx = iBestFeasiblePenalty;
    fprintf('Best feasible case found at iteration %d with penalty score %.4f\n', bestIterIdx, penaltyScore(bestIterIdx));
else
    % Fallback: If no cases met all tolerances, pick the lowest total cost overall
    warning('No completely feasible cases found. Defaulting to the lowest total cost.');
    bestIterIdx = iBestTotal;
    fprintf('Best overall case (infeasible) found at iteration %d with total cost %.4f\n', bestIterIdx, totalCost(bestIterIdx));
end


%% Plot Flow Fields for the Best Case
% Make sure yRange and L are defined in your script (adjust if necessary)
ymin = -0.2206;
ymax = 0.0823;
ydist = ymax - ymin;
% yRange = [-0.0650 0.1396];
yRange = [ymin+0.05*ydist ymax-0.05*ydist];
% L = 0.087;
L = 0.123;

% Convert the local iteration index to the global optDB index
bestGlobalIdx = idxCase(bestIterIdx);

% Extract the fields directly from optDB
bestFields = optDB(bestGlobalIdx).fields; 

% Call the plotting function
plotBestCaseProfiles(bestFields, yRange, L, targetDefs);


%% Export Data for LaTeX / PGFPlots
fprintf('\n--- Exporting data for PGFPlots ---\n');

% 1. Export the convergence history
% The resultsTable already contains almost everything (caseIter, totalCost, etc.)
% We write it out with whitespace delimiters for native PGFPlots compatibility.
exportNameHist = fullfile(csvDir, 'optimization_convergence.dat');
writetable(resultsTable, exportNameHist, 'Delimiter', ' ');
fprintf('Exported convergence history to: %s\n', exportNameHist);

% 2. Export Profiles for each Pareto Candidate
for k = 1:numel(idxPareto)
    localIdx = idxPareto(k);              % Iteration number in this case
    globalIdx = idxCase(localIdx);        % Index in the global optDB
    
    candidateFields = optDB(globalIdx).fields; 
    
    try
        % A. Extract length of y-axis from the 2D matrix
        yLen = size(candidateFields.U, 1); 
        
        % B. Calculate physical y-coordinates (transposed to column vector)
        yRangeArray = linspace(0, yRange(2)-yRange(1), yLen)' / L;
        
        % C. Calculate U profile (mean across x-axis, normalized by global mean)
        U_mean = mean(candidateFields.U, 'all', 'omitnan');
        toplot_U = mean(candidateFields.U, 2, 'omitnan') / U_mean;
        
        % D. Calculate TI profile (mean across x-axis, normalized by global mean)
        TI_mean = mean(candidateFields.TI, 'all', 'omitnan');
        toplot_TI = mean(candidateFields.TI, 2, 'omitnan') / TI_mean;
        
        % E. Write to table using the newly calculated column vectors
        T_prof = table(yRangeArray, toplot_U, toplot_TI, ...
            'VariableNames', {'y_L', 'U_norm', 'TI_norm'});
        
        fileNameProf = fullfile(csvDir, sprintf('pareto_candidate_%03d_profiles.dat', localIdx));
        writetable(T_prof, fileNameProf, 'Delimiter', ' ');
        
        fprintf('Exported profiles for candidate %d to: %s\n', localIdx, fileNameProf);
        
    catch ME
        fprintf('Warning: Could not export profiles for candidate %d.\n', localIdx);
        fprintf('  Error: %s\n', ME.message);
    end
end
fprintf('Data export complete.\n');


%% LOCAL FUNCTIONS

function caseDirs = getCaseDirs(optDB)
    n = numel(optDB);
    caseDirs = strings(n,1);

    for i = 1:n
        if isfield(optDB(i), 'caseDir') && ~isempty(optDB(i).caseDir)
            caseDirs(i) = normalizeCaseDirString(optDB(i).caseDir);
        else
            caseDirs(i) = "caseDir_unknown";
        end
    end
end


function out = normalizeCaseDirString(caseDirValue)
    % Keep selection based on caseDir but remove inconsequential trailing file
    % separators so equivalent paths do not split into separate cases.
    out = string(caseDirValue);
    out = strtrim(out);

    while strlength(out) > 0 && (endsWith(out, "\\") || endsWith(out, "/"))
        out = extractBefore(out, strlength(out));
    end
end


function Y = extractKeys(records, keys)
    n = numel(records);
    m = numel(keys);
    Y = NaN(n,m);

    for i = 1:n
        for j = 1:m
            Y(i,j) = getNestedNumeric(records(i), keys{j});
        end
    end
end


function val = getNestedNumeric(S, key)
    parts = split(string(key), '.');
    tmp = S;

    for p = 1:numel(parts)
        field = char(parts(p));
        if isstruct(tmp) && isfield(tmp, field)
            tmp = tmp.(field);
        else
            val = NaN;
            return
        end
    end

    if isnumeric(tmp) && isscalar(tmp)
        val = double(tmp);
    elseif islogical(tmp) && isscalar(tmp)
        val = double(tmp);
    else
        val = NaN;
    end
end


function scale = computePenaltyScale(Ylatest, Yall, mode)
    switch lower(string(mode))
        case "alldb_robust"
            scale = robustScale(Yall);

        case "latest_robust"
            scale = robustScale(Ylatest);

        case "alldb_std"
            scale = std(Yall, 0, 1, 'omitnan');

        case "latest_std"
            scale = std(Ylatest, 0, 1, 'omitnan');

        otherwise
            error('Unknown penaltyScaleMode: %s', mode);
    end

    % Ensure row-vector shape.
    scale = reshape(scale, 1, []);

    % Fallback if scale is invalid or too small.  This is done in two
    % explicit steps so MATLAB never tries to assign a full row vector into
    % only the subset of invalid entries.
    fallback = std(Yall, 0, 1, 'omitnan');
    fallback = reshape(fallback, 1, []);

    fallbackMeanAbs = mean(abs(Yall), 1, 'omitnan');
    fallbackMeanAbs = reshape(fallbackMeanAbs, 1, []);

    badFallback = ~isfinite(fallback) | fallback <= 0;
    fallback(badFallback) = fallbackMeanAbs(badFallback);

    badFallback = ~isfinite(fallback) | fallback <= 0;
    fallback(badFallback) = 1;

    badScale = ~isfinite(scale) | scale <= 0;
    scale(badScale) = fallback(badScale);
end


function s = robustScale(Y)
    % Robust scale from IQR. If too small, falls back elsewhere.
    q75 = prctile(Y, 75, 1);
    q25 = prctile(Y, 25, 1);
    s = (q75 - q25) ./ 1.349;
end


function bestFeas = runningBestFeasible(score, feasible)
    bestFeas = NaN(size(score));
    currentBest = Inf;

    for i = 1:numel(score)
        if feasible(i) && isfinite(score(i))
            currentBest = min(currentBest, score(i));
        end

        if isfinite(currentBest)
            bestFeas(i) = currentBest;
        end
    end
end


function pf = paretoFrontMin(F)
    % Return true for non-dominated rows of F, assuming all columns are minimised.
    n = size(F,1);
    pf = true(n,1);

    for i = 1:n
        if ~pf(i)
            continue
        end

        for j = 1:n
            if i == j
                continue
            end

            if all(F(j,:) <= F(i,:)) && any(F(j,:) < F(i,:))
                pf(i) = false;
                break
            end
        end
    end
end

