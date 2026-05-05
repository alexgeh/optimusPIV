%% ONR REVIEW PLOTS

casei = ibest; % Selected case

yRangeArray = linspace(0,yRange(2)-yRange(1),length(mean(optResults(1).fields.U,2))) / L;
yMinToMax = [yRangeArray(1), yRangeArray(end)];
yHeight = yRange(2)-yRange(1);

% -------------------------------------------------------------------------
% 1. U (Velocity) Plot
% -------------------------------------------------------------------------
U_mean = mean(optResults(casei).fields.U, 'all');
toplot_U = mean(optResults(casei).fields.U, 2) / U_mean;

% Set Position to [x, y, width, height] for a taller-than-wide aspect ratio
figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
hold on; box on;

% Swapped X and Y variables
plot(mean(toplot_U)*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', 'black');
plot(toplot_U, yRangeArray, "LineWidth", 3, 'Color', [54, 86, 150] / 255);

% Formatting
xlabelg("$$U / \bar{U}$$"); 
ylabelg("$$y / L$$");
ylim(yMinToMax);
xlim([0.8 1.2]); 

ax = gca; 
ax.FontSize = 28; 
ax.LineWidth = 1.0; % Double the default axis line width (0.5)

% Export
fname_U = fullfile(plotDir, 'distributions', 'U_mean', sprintf('U_mean_%.4d_zoom.svg', casei));
% export_fig(fname_U, '-transparent', '-svg');

% -------------------------------------------------------------------------
% 2. TI (Turbulence Intensity) Plot
% -------------------------------------------------------------------------
toplot_TI = mean(optResults(casei).fields.TI, 2);

% Set Position to [x, y, width, height] for a taller-than-wide aspect ratio
figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
hold on; box on;

% Swapped X and Y variables
plot(toplot_TI, yRangeArray, "LineWidth", 3, 'Color', defaultOrange);
plot(mean(toplot_TI)*ones(2,1), yMinToMax, '--', "LineWidth", 1, 'Color', lightOrange);
% plot(TI_target*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', 'black');

% Formatting
xlabelg("$$TI$$"); 
ylabelg("$$y / L$$");
ylim(yMinToMax);
xlim([0 0.35]); xticks(0:0.1:0.4); 

ax = gca; 
ax.FontSize = 28; 
ax.LineWidth = 1.0; % Double the default axis line width (0.5)

% Export
fname_TI = fullfile(plotDir, 'distributions', 'TI_mean', sprintf('TI_mean_%.4d_zoom.svg', casei));
% export_fig(fname_TI, '-transparent', '-svg');

%%
switch optID
    case 6
        % -----------------------------------------------------------------
        % U
        % -----------------------------------------------------------------
        U_mean = mean(optResults(ibest).fields.U,'all');
        toplot_U = mean(optResults(ibest).fields.U,2) / U_mean;
        dUdy_mean = mean(optResults(ibest).fields.dUdy,'all') / U_mean;
        dUdy_Delta = dUdy_mean*yHeight/2;

        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        % plot(mean(toplot_U)*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', 'black');
        plot([mean(toplot_U)-dUdy_Delta, mean(toplot_U)+dUdy_Delta], yMinToMax, "LineWidth", 1, 'Color', lightOrange);
        plot(toplot_U, yRangeArray, "LineWidth", 3, 'Color', [54, 86, 150] / 255);
        
        xlabelg("$$U / U_\infty$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        xlim([0.8 1.2]); 
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;

        % -----------------------------------------------------------------
        % dU_dy
        % -----------------------------------------------------------------
        toplot_dUdy = mean(optResults(ibest).fields.dUdy,2);
        
        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(mean(toplot_dUdy)*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', lightOrange);
        plot(dudy_target*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', 'black');
        plot(toplot_dUdy, yRangeArray, "LineWidth", 3, 'Color', [54, 86, 150] / 255);
        
        xlabelg("$$dU/dy$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;

        % -----------------------------------------------------------------
        % NEW du_dy
        % -----------------------------------------------------------------
        U_mean_new = mean(optResults(casei).fields.U,'all');
        toplot_U_new = mean(optResults(casei).fields.U,2) / U_mean_new;
        dUdy_mean_new = mean(optResults(ibest).fields.dUdy,'all');
        dUdy_Delta_new = dUdy_mean_new*yHeight/2 / U_mean_new;
        
        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(toplot_U_new, yRangeArray, "LineWidth", 3, 'Color', [54, 86, 150] / 255);
        plot([mean(toplot_U_new)-dUdy_Delta_new, mean(toplot_U_new)+dUdy_Delta_new], yMinToMax, '--', "LineWidth", 1, 'Color', lightOrange);
        
        xlabelg("$$U / \bar{U}$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        xlim([0.8 1.2]);
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;
        
        fname = fullfile(plotDir, 'distributions', 'U_mean', sprintf('U_mean_%.4d.svg', casei));
        % export_fig(fname, '-transparent', '-svg');

        % -----------------------------------------------------------------
        % TI
        % -----------------------------------------------------------------
        toplot_TI = mean(optResults(ibest).fields.TI,2);
        dTIdy_mean = mean(optResults(ibest).fields.dTIdy,'all');
        dTIdy_Delta = dTIdy_mean*yHeight/2;

        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(toplot_TI, yRangeArray, "LineWidth", 3, 'Color', defaultOrange);
        % plot(mean(toplot_TI)*ones(2,1), [0 yHeight]);
        plot([mean(toplot_TI)-dTIdy_Delta, mean(toplot_TI)+dTIdy_Delta], yMinToMax, "LineWidth", 1, 'Color', lightOrange);
        
        xlabelg("$$TI$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        xlim([0 0.35]); xticks(0:0.1:0.4); 
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;

        % -----------------------------------------------------------------
        % dTI_dy
        % -----------------------------------------------------------------
        toplot_dTIdy = mean(optResults(ibest).fields.dTIdy,2);
        
        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(toplot_dTIdy, yRangeArray, "LineWidth", 3, 'Color', defaultOrange);
        plot(mean(toplot_dTIdy)*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', lightOrange);
        % plot(-0.2*ones(2,1), yMinToMax, 'Color', 'black');
        
        xlabelg("$$dTI/dy$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;

    case 7
        % -----------------------------------------------------------------
        % TI
        % -----------------------------------------------------------------
        toplot_TI = mean(optResults(casei).fields.TI,2);
        dTIdy_mean = mean(optResults(ibest).fields.dTIdy,'all');
        dTIdy_Delta = dTIdy_mean*yHeight/2;

        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(toplot_TI, yRangeArray, "LineWidth", 3, 'Color', defaultOrange);
%         plot(TI_target*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', 'black');
%         plot(mean(toplot_TI)*ones(2,1), yMinToMax, '--', "LineWidth", 1, 'Color', lightOrange);
        plot([mean(toplot_TI)-dTIdy_Delta, mean(toplot_TI)+dTIdy_Delta], yMinToMax, '--', "LineWidth", 1, 'Color', lightOrange);
        
        xlabelg("$$TI$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        xlim([0 0.35]); 
        xticks(0:0.1:0.4);
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;
        
        fname = fullfile(plotDir, 'distributions', 'TI_mean', sprintf('dTIdy_%.4d.svg', casei));
        % export_fig(fname, '-transparent', '-svg');

        % -----------------------------------------------------------------
        % dTI_dy
        % -----------------------------------------------------------------
        toplot_dTIdy = mean(optResults(ibest).fields.dTIdy,2);
        
        figure('Color', 'white', 'Position', [100, 100, 450, 600]); 
        hold on; box on;
        plot(toplot_dTIdy, yRangeArray, "LineWidth", 3, 'Color', defaultOrange);
        plot(mean(toplot_dTIdy)*ones(2,1), yMinToMax, "LineWidth", 1, 'Color', lightOrange);
        % plot(-0.2*ones(2,1), yMinToMax, 'Color', 'black');
        
        xlabelg("$$dTI/dy$$"); 
        ylabelg("$$y / L$$");
        ylim(yMinToMax);
        
        ax = gca; 
        ax.FontSize = 28; 
        ax.LineWidth = 1.0;
end