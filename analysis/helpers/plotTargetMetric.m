function plotTargetMetric(metric, target, tolPercent)
% plotTargetMetric  Plot metric over iterations and highlight values near a target
%
%   plotTargetMetric(metric, target, tolPercent)
%
%   Inputs:
%       metric      : Vector of metric values (size [nIterations x 1])
%       target      : Target value for the metric
%       tolPercent  : Tolerance range in percent (e.g., 5 for ±5%)
%
%   This function plots all metric values over iterations, highlights
%   those within ±tolPercent of the target, and draws reference lines
%   for the target and its tolerance band.

    % Ensure column vector
    metric = metric(:);
    nIter = numel(metric);
    iter = 1:nIter;

    % Compute tolerance band
    tolAbs = target * tolPercent / 100;
    lowerBound = target - tolAbs;
    upperBound = target + tolAbs;

    % Identify in-range points
    inRange = metric >= lowerBound & metric <= upperBound;

    % Prepare figure
    figure; hold on; grid on; box on;

    % Plot all points
    plot(iter, metric, 'o', ...
        'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'k');

    % Highlight in-range points
    plot(iter(inRange), metric(inRange), 'o', ...
        'MarkerFaceColor', [0.0 0.6 0.2], 'MarkerEdgeColor', 'k', ...
        'MarkerSize', 7);

    % Plot target and tolerance lines
    yline(target, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.5);
    yline(upperBound, '--', 'Color', [0.6 0.6 0.6]);
    yline(lowerBound, '--', 'Color', [0.6 0.6 0.6]);

%     yline(target, '-', sprintf('Target = %.3g', target), ...
%         'Color', [0 0.45 0.74], 'LineWidth', 1.5);
%     yline(upperBound, '--', sprintf('+%.1f%%', tolPercent), ...
%         'Color', [0.6 0.6 0.6]);
%     yline(lowerBound, '--', sprintf('-%.1f%%', tolPercent), ...
%         'Color', [0.6 0.6 0.6]);

    xlabelg('Iteration');
    ylabelg('Target value');
    title(sprintf('Metric vs. Iteration (Target = %.3g ±%.1f%%)', ...
        target, tolPercent));
    legend('All points', 'Within target range', 'Location', 'best');
end
