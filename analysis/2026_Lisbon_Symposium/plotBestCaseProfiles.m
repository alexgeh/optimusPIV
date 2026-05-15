function plotBestCaseProfiles(fields, yRange, L, targetDefs)
    % plotBestCaseProfiles Generates U, TI, and dTI/dy vertical profile plots 
    % for the selected best optimization case.
    %
    % Inputs:
    %   fields     - Struct containing the flow fields (U, TI, dTIdy)
    %   yRange     - 1x2 array defining the physical y-limits of the FOV [min, max]
    %   L          - Characteristic length scale
    %   targetDefs - Struct array containing optimization targets (for reference lines)

    %% 0. Setup Y-Axis Arrays
    % Assume fields.U is a 2D matrix [y, x]. We average across x (dimension 2).
    yLen = size(fields.U, 1); 
    yRangeArray = linspace(0, yRange(2)-yRange(1), yLen) / L;
    yMinToMax = [yRangeArray(1), yRangeArray(end)];
    
    % Colors matching original ONR plots
    blueColor = [54, 86, 150] / 255;
    orangeColor = [218, 100, 38] / 255;

    %% 1. U (Velocity) Plot
    U_mean = mean(fields.U, 'all', 'omitnan');
    toplot_U = mean(fields.U, 2, 'omitnan') / U_mean;

    % Calculate linear best fit for U (ignoring any NaNs from PIV masks)
    valid_U = ~isnan(toplot_U(:)) & ~isnan(yRangeArray(:));
    p_U = polyfit(yRangeArray(valid_U), toplot_U(valid_U), 1);
    fit_U = polyval(p_U, yRangeArray);

    figure('Color', 'white', 'Position', [100, 100, 450, 600], 'Name', 'Best Case: Velocity Profile'); 
    hold on; box on;
    
    % Plot mean reference line
    plot(mean(toplot_U)*ones(2,1), yMinToMax, 'LineWidth', 1, 'Color', 'black');
    
    % Plot actual data and linear fit
    plot(toplot_U, yRangeArray, 'LineWidth', 3, 'Color', blueColor);
    plot(fit_U, yRangeArray, '--', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]); % Dark grey dashed fit
    
    xlabel('$$U(y) / \bar{U}$$', 'Interpreter', 'latex', 'FontSize', 28); 
    ylabel('$$y / L$$', 'Interpreter', 'latex', 'FontSize', 28);
    ylim(yMinToMax);
    xlim([0.8 1.2]); 
    % xticks(0.8:0.1:1.2);
    
    ax = gca; 
    ax.FontSize = 28; 
    ax.LineWidth = 1.0;

    %% 2. TI (Turbulence Intensity) Plot
    toplot_TI = mean(fields.TI, 2, 'omitnan') / mean(fields.TI(:), 'omitnan');
    
    % Calculate linear best fit for TI (ignoring any NaNs from PIV masks)
    valid_TI = ~isnan(toplot_TI(:)) & ~isnan(yRangeArray(:));
    p_TI = polyfit(yRangeArray(valid_TI), toplot_TI(valid_TI), 1);
    fit_TI = polyval(p_TI, yRangeArray);

    figure('Color', 'white', 'Position', [150, 100, 450, 600], 'Name', 'Best Case: TI Profile'); 
    hold on; box on;

    % Plot mean reference line
    plot(mean(toplot_TI)*ones(2,1), yMinToMax, 'LineWidth', 1, 'Color', 'black');
    
    % Plot actual data and linear fit
    plot(toplot_TI, yRangeArray, 'LineWidth', 3, 'Color', orangeColor);
    plot(fit_TI, yRangeArray, '--', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]); % Dark grey dashed fit
    
    % Extract and plot TI Target if it exists in targetDefs
    % for i = 1:numel(targetDefs)
    %     if strcmp(targetDefs(i).name, 'TI_mean')
    %         plot(targetDefs(i).target*ones(2,1), yMinToMax, '--', 'LineWidth', 1.5, 'Color', 'black');
    %         break;
    %     end
    % end
    
    xlabel('$$TI(y) / \bar{TI}$$', 'Interpreter', 'latex', 'FontSize', 28); 
    ylabel('$$y / L$$', 'Interpreter', 'latex', 'FontSize', 28);
    ylim(yMinToMax);
    % Adjust xlim dynamically based on max TI, or hardcode to [0 0.35] if preferred
    % xMaxTI = max(0.35, ceil(max(toplot_TI)*10)/10);
    % xlim([0 xMaxTI]); 
    xlim([0.8 1.2])
    
    ax = gca; 
    ax.FontSize = 28; 
    ax.LineWidth = 1.0;

end