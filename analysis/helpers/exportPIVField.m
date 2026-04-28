function exportPIVField(x, y, fieldData, fname, opts)
    % exportPIVField Plots and exports a 2D scalar field.
    % 
    % Inputs:
    %   x, y      : Grid coordinates (pass empty arrays [] to use matrix indices)
    %   fieldData : 2D matrix of the field to plot
    %   fname     : Full file path for the exported image
    %   opts      : Struct containing plot options (cmap, cLabel, isLatex, nLevel)
    
    % Set default options if not provided
    if ~isfield(opts, 'cmap'); opts.cmap = 'jet'; end
    if ~isfield(opts, 'cLabel'); opts.cLabel = ''; end
    if ~isfield(opts, 'isLatex'); opts.isLatex = false; end
    if ~isfield(opts, 'nLevel'); opts.nLevel = 40; end
    if ~isfield(opts, 'limits')
        % Default limit calculation
        fMean = mean(fieldData(:), 'omitnan');
        fStd = std(fieldData(:), 'omitnan');
        opts.limits = [fMean - 2*fStd, fMean + 2*fStd];
    end

    % Create contour levels
    levels = [nanmin2(fieldData), linspace(opts.limits(1), opts.limits(2), opts.nLevel), nanmax2(fieldData)];
    
    % Plotting
    if isempty(x) || isempty(y)
        [~, h] = contourf(fieldData, levels);
    else
        [~, h] = contourf(x, y, fieldData, levels);
    end
    set(h, 'linestyle', 'none');
    
    if isfield(opts, 'axisEqual') && opts.axisEqual
        axis equal;
    end
    
    % Formatting
    colormap(opts.cmap);
    clim(opts.limits);
    hcb = colorbar;
    hcb.Label.String = opts.cLabel;
    
    if opts.isLatex
        hcb.Label.Interpreter = 'latex';
        xlabelg('$$x/L$$'); ylabelg('$$y/L$$'); 
    end
    
    hcb.FontSize = 14; 
    hcb.Label.FontSize = 14;
    
    ax = gca; 
    ax.XAxis.FontSize = 14; 
    ax.YAxis.FontSize = 14;
    
    if isfield(opts, 'customTicks') && opts.customTicks
        xticks(0:1:4); yticks(0:1:4);
    end

    % Export
    set(gcf, 'Color', 'white');
    export_fig(fname, '-png', '-transparent', '-opengl', '-r600');
    clf; % Clear figure for the next loop to prevent memory bloat
end
