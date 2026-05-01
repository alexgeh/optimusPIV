function actLearn_plotStatus(X_run, Y_run, history, input_defs, output_defs, AL_settings, iter)
%% Plot active-learning status for the current run only.
%
% X_run/Y_run should contain only values recorded after this script started.
% This avoids overcrowding when the GP is trained from a much larger optDB.
%
% Plotting behaviour:
%   - In exploration mode, target-cost traces are suppressed because they are
%     not meaningful and can obscure the exploration trends.
%   - Output metrics are plotted in normalised form in subplot 2 so that
%     large-magnitude quantities such as dU/dy do not dominate the axis.

if isempty(Y_run)
    return
end

nKeep = min(size(Y_run,1), AL_settings.plotWindow);
rowIdx = (size(Y_run,1)-nKeep+1):size(Y_run,1);
Xp = X_run(rowIdx,:);
Yp = Y_run(rowIdx,:);

outputNames = {output_defs.name};
outputLabels = {output_defs.label};
inputLabels = {input_defs.label};

isExploreMode = isfield(AL_settings, 'current_strategy') && ...
    contains(lower(string(AL_settings.current_strategy)), "explore");

tiIdx = find(strcmp(outputNames, 'TI_mean'), 1, 'first');
if isempty(tiIdx)
    tiIdx = 1;
end

figure(101); clf;

%% 1) Main target/first metric tracking
subplot(2,2,1);
plot(rowIdx, Yp(:,tiIdx), 'k-o', 'LineWidth', 1, 'MarkerFaceColor', 'g'); hold on;

% In exploration mode, suppress target references because they are not
% part of the active objective and visually compete with exploration trends.
if ~isExploreMode && isfield(output_defs(tiIdx), 'target') && isfinite(output_defs(tiIdx).target)
    yline(output_defs(tiIdx).target, 'r--', 'Target');
end

title(sprintf('Current run, iter %d: %s', iter, outputLabels{tiIdx}));
xlabel('Current-run sample');
ylabel(outputLabels{tiIdx});
grid on;

%% 2) Normalised measured output metrics
subplot(2,2,2);
hold on;

% Use all output metrics here, not only the non-TI metrics. The goal is
% to see relative movement/exploration across metrics without dU/dy or
% another high-magnitude quantity dominating the axis.
YpNorm = normalizeOutputMetricsForPlot(Yp);

for k = 1:size(YpNorm,2)
    plot(rowIdx, YpNorm(:,k), '-o', 'DisplayName', outputLabels{k});
end

title('Current-run output metrics, normalised');
xlabel('Current-run sample');
ylabel('Normalised value within plotted window');
ylim([-0.05, 1.05]);
legend('Location','best');
grid on;

%% 3) Improvement/progress indicators
subplot(2,2,3);
hold on;

isExploreMode = contains(lower(AL_settings.current_strategy), 'explore');

if isExploreMode
    selectedExplore = getFieldOrNaN(acqHistory, 'exploreScore');
    rawUnc          = getFieldOrNaN(acqHistory, 'rawUncertaintyScore');
    antiCluster     = getFieldOrNaN(acqHistory, 'antiClusterPenalty');

    globalMean   = getFieldOrNaN(acqHistory, 'globalMeanUncertainty');
    globalMedian = getFieldOrNaN(acqHistory, 'globalMedianUncertainty');
    globalP90    = getFieldOrNaN(acqHistory, 'globalP90Uncertainty');
    globalP99    = getFieldOrNaN(acqHistory, 'globalP99Uncertainty');

    plot(iterVec, selectedExplore, 'o-', 'DisplayName', 'selected explore score');
    hold on;
    plot(iterVec, globalMean, 's-', 'DisplayName', 'global mean uncertainty');
    plot(iterVec, globalMedian, 'd-', 'DisplayName', 'global median uncertainty');
    plot(iterVec, globalP90, '^-', 'DisplayName', 'global P90 uncertainty');
    plot(iterVec, globalP99, 'v-', 'DisplayName', 'global P99 uncertainty');
    hold off;

    xlabel('Current run iteration');
    ylabel('Normalised uncertainty');
    title('Exploration convergence');
    legend('Location','best');
    grid on;
else

    hIdx = max(1, numel(history.iter)-nKeep+1):numel(history.iter);

    if ~isempty(hIdx)
        if any(isfinite(history.exploreScore(hIdx)))
            plot(history.iter(hIdx), history.exploreScore(hIdx), '-o', ...
                'DisplayName', 'Exploration score = uncertainty × penalty');
        end

        if isfield(history, 'rawUncertaintyScore') && any(isfinite(history.rawUncertaintyScore(hIdx)))
            plot(history.iter(hIdx), history.rawUncertaintyScore(hIdx), '--o', ...
                'DisplayName', 'Raw uncertainty score');
        end

        if isfield(history, 'antiClusterPenalty') && any(isfinite(history.antiClusterPenalty(hIdx)))
            plot(history.iter(hIdx), history.antiClusterPenalty(hIdx), '--x', ...
                'DisplayName', 'Anti-cluster penalty');
        end

        % Target scores are only meaningful in target/optimisation mode.
        % They are often much larger than exploration scores, so suppress them
        % during exploration to keep the exploration trends readable.
        if ~isExploreMode
            if isfield(history, 'targetCostPred') && any(isfinite(history.targetCostPred(hIdx)))
                plot(history.iter(hIdx), history.targetCostPred(hIdx), '-s', ...
                    'DisplayName', 'Predicted target cost');
            end

            if isfield(history, 'targetCostMeasured') && any(isfinite(history.targetCostMeasured(hIdx)))
                plot(history.iter(hIdx), history.targetCostMeasured(hIdx), '-d', ...
                    'DisplayName', 'Measured target score');
            end
        end
    end
end

if isExploreMode
    title('Exploration progress');
else
    title('Progress indicator');
end
xlabel('Iteration');
ylabel('Dimensionless score');
legend('Location','best');
grid on;

%% 4) Sampling map in first two active dimensions
subplot(2,2,4);
if size(Xp,2) >= 2
    scatter(Xp(:,1), Xp(:,2), 45, Yp(:,tiIdx), 'filled');
    xlabel(inputLabels{1});
    ylabel(inputLabels{2});
    title(sprintf('Current-run sampling map (color = %s)', outputLabels{tiIdx}));
    colorbar;
    grid on;
else
    scatter(Xp(:,1), Yp(:,tiIdx), 45, Yp(:,tiIdx), 'filled');
    xlabel(inputLabels{1});
    ylabel(outputLabels{tiIdx});
    title('Current-run sampling map');
    colorbar;
    grid on;
end

drawnow;
end


function Yn = normalizeOutputMetricsForPlot(Y)
%% Normalise each output column to [0, 1] over the plotted window.
%
% This is only for plotting. It does not affect the optimisation/acquisition.
% Constant or nearly constant columns are plotted at 0.5 so they remain visible
% without implying artificial variation.

Yn = NaN(size(Y));

for k = 1:size(Y,2)
    y = Y(:,k);
    valid = isfinite(y);

    if ~any(valid)
        continue
    end

    ymin = min(y(valid));
    ymax = max(y(valid));
    yrange = ymax - ymin;

    if ~isfinite(yrange) || yrange < eps
        Yn(valid,k) = 0.5;
    else
        Yn(valid,k) = (y(valid) - ymin) ./ yrange;
    end
end
end


function values = getFieldOrNaN(S, fieldName)

    n = numel(S);
    values = NaN(n,1);

    for i = 1:n
        if isfield(S(i), fieldName) && ~isempty(S(i).(fieldName))
            values(i) = S(i).(fieldName);
        end
    end
end
