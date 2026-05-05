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

hIdx = max(1, numel(history.iter)-nKeep+1):numel(history.iter);
isExploreMode = contains(lower(AL_settings.current_strategy), 'explore');

if ~isempty(hIdx)

    if isExploreMode
        selectedExplore = getHistoryField(history, 'exploreScore', hIdx);
        rawUnc          = getHistoryField(history, 'rawUncertaintyScore', hIdx);
        antiCluster     = getHistoryField(history, 'antiClusterPenalty', hIdx);

        globalMean   = getHistoryField(history, 'globalMeanUncertainty', hIdx);
        globalMedian = getHistoryField(history, 'globalMedianUncertainty', hIdx);
        globalP90    = getHistoryField(history, 'globalP90Uncertainty', hIdx);
        globalP99    = getHistoryField(history, 'globalP99Uncertainty', hIdx);

        if any(isfinite(selectedExplore))
            plot(history.iter(hIdx), selectedExplore, '-o', ...
                'DisplayName', 'selected explore score');
        end

        if any(isfinite(globalMean))
            plot(history.iter(hIdx), globalMean, '-s', ...
                'DisplayName', 'global mean uncertainty');
        end

        if any(isfinite(globalMedian))
            plot(history.iter(hIdx), globalMedian, '-d', ...
                'DisplayName', 'global median uncertainty');
        end

        if any(isfinite(globalP90))
            plot(history.iter(hIdx), globalP90, '-^', ...
                'DisplayName', 'global P90 uncertainty');
        end

        if any(isfinite(globalP99))
            plot(history.iter(hIdx), globalP99, '-v', ...
                'DisplayName', 'global P99 uncertainty');
        end

        if any(isfinite(rawUnc))
            plot(history.iter(hIdx), rawUnc, '--', ...
                'DisplayName', 'raw selected uncertainty');
        end

        if any(isfinite(antiCluster))
            plot(history.iter(hIdx), antiCluster, ':', ...
                'DisplayName', 'anti-cluster penalty');
        end

        title('Exploration convergence');
        ylabel('Normalised uncertainty');

    else
        targetCostPred   = getHistoryField(history, 'targetCostPred', hIdx);
        targetScore      = getHistoryField(history, 'targetScore', hIdx);
        penaltyScore     = getHistoryField(history, 'penaltyScore', hIdx);
        targetViolation  = getHistoryField(history, 'targetViolation', hIdx);
        measuredScore    = getHistoryField(history, 'targetCostMeasured', hIdx);

        if any(isfinite(targetCostPred))
            plot(history.iter(hIdx), targetCostPred, '-s', ...
                'DisplayName', 'predicted total cost');
        end

        if any(isfinite(targetScore))
            plot(history.iter(hIdx), targetScore, '-o', ...
                'DisplayName', 'predicted target score');
        end

        if any(isfinite(targetViolation))
            plot(history.iter(hIdx), targetViolation, '-x', ...
                'DisplayName', 'target violation');
        end

        if any(isfinite(penaltyScore))
            plot(history.iter(hIdx), penaltyScore, '-^', ...
                'DisplayName', 'predicted CV/aniso penalty');
        end

        if any(isfinite(measuredScore))
            plot(history.iter(hIdx), measuredScore, '-d', ...
                'DisplayName', 'measured target score');
        end

        title('Targeted optimisation progress');
        ylabel('Dimensionless cost / score');
    end
end

xlabel('Iteration');
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

function values = getHistoryField(history, fieldName, idx)

    values = NaN(numel(idx),1);

    if ~isstruct(history) || ~isfield(history, fieldName)
        return
    end

    raw = history.(fieldName);

    if isempty(raw)
        return
    end

    valid = idx <= numel(raw);
    values(valid) = raw(idx(valid));
end
