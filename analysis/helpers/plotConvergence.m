function plotConvergence(J, varargin)
% plotConvergence  Plot optimization progress with highlighted improvements
%
%   plotConvergence(J)
%   plotConvergence(J, 'AllColor', [...], 'ImpColor', [...], 'MarkerFaceColor', [...])
%
%   Inputs:
%       J : Vector of fitness values (size [nIterations x 1])
%
%   Name–value optional inputs:
%       'AllColor'        : Color of all-iteration markers (default: [0.7 0.7 0.7])
%       'AllEdgeColor'    : Edge color of all-iteration markers (default: 'k')
%       'ImpColor'        : Color of improvement line & markers (default: [0 0.45 0.74])
%       'ImpLineWidth'    : Line width of improvement curve (default: 1.5)

    % -------------------------
    % Parse optional inputs
    % -------------------------
    p = inputParser;
    p.CaseSensitive = false;

    addParameter(p, 'AllColor',        [0.7 0.7 0.7]);
    addParameter(p, 'AllEdgeColor',    'k');
    addParameter(p, 'ImpColor',        [0 0.45 0.74]);
    addParameter(p, 'ImpLineWidth',    1.5);

    parse(p, varargin{:});
    opts = p.Results;

    % -------------------------
    % Ensure column vector
    % -------------------------
    J = J(:);
    nIter = numel(J);
    iter = 1:nIter;

    % -------------------------
    % Identify improvement points
    % -------------------------
    Jmin = J(1);
    isImprovement = false(size(J));
    isImprovement(1) = true;

    for k = 2:nIter
        if J(k) < Jmin
            Jmin = J(k);
            isImprovement(k) = true;
        end
    end

    % -------------------------
    % Plot
    % -------------------------
    figure(7456); hold on;
    box on;

    % All iterations
    plot(iter, J, 'o', ...
        'MarkerFaceColor', opts.AllColor, ...
        'MarkerEdgeColor', opts.AllEdgeColor);

    % Improvement curve
    impIdx = find(isImprovement);
    plot(iter(impIdx), J(impIdx), '-o', ...
        'Color', opts.ImpColor, ...
        'MarkerFaceColor', opts.ImpColor, ...
        'LineWidth', opts.ImpLineWidth);

    % Extend last improvement horizontally
    if ~isempty(impIdx)
        lastImpIter = impIdx(end);
        lastImpVal  = J(lastImpIter);
        plot([lastImpIter nIter], [lastImpVal lastImpVal], ...
            'Color', opts.ImpColor, ...
            'LineWidth', opts.ImpLineWidth - 0.3);
    end

    xlabelg('Iteration');
    ylabelg('Fitness value, $$J$$');
%     legend('All iterations', 'Improvements', 'Location', 'best');
end
