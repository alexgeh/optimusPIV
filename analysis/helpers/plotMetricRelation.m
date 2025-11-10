function plotMetricRelation(xMetric, yMetric, varargin)
% plotMetricRelation  Plot relationship between two metrics with optional linear fit
%
%   plotMetricRelation(xMetric, yMetric)
%   plotMetricRelation(xMetric, yMetric, 'fit', true)
%   plotMetricRelation(xMetric, yMetric, 'fit', true, 'xlabel', 'Amplitude', 'ylabel', 'TI')
%
%   Inputs:
%       xMetric : Vector of x-values (e.g. amplitude)
%       yMetric : Vector of y-values (e.g. turbulence intensity)
%
%   Optional name-value arguments:
%       'fit'    : logical (default=false)
%                  If true, plots a linear regression line and displays equation & R²
%       'xlabel' : string (default='xMetric')
%       'ylabel' : string (default='yMetric')
%
%   Example:
%       plotMetricRelation(amp, TI, 'fit', true, 'xlabel', 'Amplitude', 'ylabel', 'TI')

    % Parse inputs
    p = inputParser;
    addParameter(p, 'fit', false, @islogical);
    addParameter(p, 'xlabel', 'xMetric', @ischar);
    addParameter(p, 'ylabel', 'yMetric', @ischar);
    parse(p, varargin{:});
    doFit = p.Results.fit;
    xlab = p.Results.xlabel;
    ylab = p.Results.ylabel;

    % Ensure column vectors
    xMetric = xMetric(:);
    yMetric = yMetric(:);

    % Prepare figure
    figure; hold on; grid on; box on;

    % Scatter plot
    plot(xMetric, yMetric, 'o', ...
        'MarkerFaceColor', [0.7 0.7 0.7], ...
        'MarkerEdgeColor', 'k', 'MarkerSize', 7);

    % Linear fit if requested
    if doFit
        % Fit: y = a*x + b
        coeffs = polyfit(xMetric, yMetric, 1);
        yFit = polyval(coeffs, xMetric);

        % Compute R^2
        SSres = sum((yMetric - yFit).^2);
        SStot = sum((yMetric - mean(yMetric)).^2);
        R2 = 1 - SSres/SStot;

        % Plot regression line
        xLine = linspace(min(xMetric), max(xMetric), 100);
        yLine = polyval(coeffs, xLine);
        plot(xLine, yLine, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.5);

        % Annotate equation and R²
%         eqStr = sprintf('y = %.3g·x + %.3g  (R² = %.3f)', coeffs(1), coeffs(2), R2);
%         text(0.05, 0.95, eqStr, 'Units', 'normalized', ...
%             'VerticalAlignment', 'top', 'FontSize', 9, ...
%             'Color', [0 0.45 0.74], 'FontName', 'Consolas');
    end

    xlabel(xlab);
    ylabel(ylab);
%     title(sprintf('%s vs. %s', ylab, xlab));
end
