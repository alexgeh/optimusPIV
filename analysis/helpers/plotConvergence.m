function plotConvergence(J)
% plotConvergence  Plot optimization progress with highlighted improvements
%
%   plotConvergence(J)
%
%   Inputs:
%       J : Vector of fitness values (size [nIterations x 1])
%
%   This function plots all fitness values as markers and connects
%   only the improving iterations (monotonic decreases of J)
%   to highlight convergence behavior. After the last improvement,
%   the improvement line continues horizontally to the final iteration
%   to indicate the optimization floor.

    % Ensure J is a column vector
    J = J(:);
    nIter = numel(J);
    iter = 1:nIter;

    % Identify improvement points (strictly decreasing)
    Jmin = J(1);
    isImprovement = false(size(J));
    isImprovement(1) = true;
    for k = 1:nIter
        if J(k) < Jmin
            Jmin = J(k);
            isImprovement(k) = true;
        end
    end

    % Prepare figure
    figure; hold on; grid on; box on;

    % Plot all points
    plot(iter, J, 'o', 'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', 'k');

    % Plot improvement curve
    impIdx = find(isImprovement);
    plot(iter(impIdx), J(impIdx), '-o', ...
        'Color', [0 0.45 0.74], 'MarkerFaceColor', [0 0.45 0.74], ...
        'LineWidth', 1.5);

    % Extend last improvement horizontally to end
    if ~isempty(impIdx)
        lastImpIter = impIdx(end);
        lastImpVal = J(lastImpIter);
        plot([lastImpIter nIter], [lastImpVal lastImpVal], ...
            'Color', [0 0.45 0.74], 'LineWidth', 1.2);
    end

    xlabelg('Iteration');
    ylabelg('Fitness value, $$J$$');
    title('Optimization Convergence');
    legend('All iterations', 'Improvements', 'Location', 'best');
end

