%% Script to analyze ATG PIV optimization
%#ok<*SAGROW>
clear


%% Processing parameters:
localPC = 1; % 1: office PC, 2: Legion (laptop)
optID = 10; % Specific case to look at
acqDate = 20260424;
plotPIV = false; % Plot PIV - !! Will take VEEERY long !!
% L = 0.123; % Characteristic length [m], diagonal length of panels
L = 0.087; % Characteristic length [m], width of panels

% Set up local file directories:
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\";
    % plotRootDir = "R:\ENG_Breuer_Shared\agehrke\PLOTS\2026_optimusPIV\";
    plotRootDir = "C:\Users\agehrke\Desktop\TEMP\2026_optimusPIV\";
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2026_optimusPIV\fullOptimizations\";
    plotRootDir = fullfile("C:\Users\alexg\Downloads\TMPDATA_2026_optimusPIV\plots\");
end
load(fullfile(rootDataDir, 'optDB.mat')); % Load all the optimization data
variousColorMaps(); % Colors and colormaps
% subDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID))); % Secondary data base only for one case
subDB = DB_filterCases(optDB, 'caseID', @(d) startsWith(d, num2str(acqDate))); % Secondary data base only for one case

procPivDirFunc = @(caseDir,ms) fullfile(caseDir, 'proc_PIV', sprintf('ms%.4d', ms));


%% Extract parameters and quantities
% All cases:
dataALL = DB_extractData(optDB, {...
    'metrics.TI_mean','metrics.TIgrad_mean'...
    ,'metrics.dTIdy_mean','metrics.CV','metrics.velgrad_mean'...
    ,'metrics.dudy_mean','metrics.aniso_mean'...
    ,'actuation.freq','actuation.ampl','actuation.offset'...
    ,'actuation.ampgrad','actuation.offsetgrad'});
% Assign zeros instead of NaN to make the data available across cases:
dataALL.actuation_ampgrad(isnan(dataALL.actuation_ampgrad)) = 0;
dataALL.actuation_offsetgrad(isnan(dataALL.actuation_offsetgrad)) = 0;
% Group by input (X) and output (Y):
X = [dataALL.actuation_freq,dataALL.actuation_ampl,dataALL.actuation_offset...
    ,dataALL.actuation_ampgrad,dataALL.actuation_offsetgrad];
Y = [dataALL.metrics_TI_mean,dataALL.metrics_TIgrad_mean,dataALL.metrics_dTIdy_mean...
    ,dataALL.metrics_CV,dataALL.metrics_velgrad_mean,dataALL.metrics_dudy_mean...
    ,dataALL.metrics_aniso_mean];
paramNames = {'freq','ampl','offset','ampgrad','offsetgrad'};
metricNames = {'TI_mean','TIgrad_mean','dTIdy_mean','CV','velgrad_mean',...
    'dudy_mean','aniso_mean'};

% Specific case:
J = DB_extractData(subDB, 'J');
data = DB_extractData(subDB, {...
    'metrics.TI_mean','metrics.TIgrad_mean'...
    ,'metrics.dTIdy_mean','metrics.CV','metrics.velgrad_mean'...
    ,'metrics.dudy_mean','metrics.aniso_mean'...
    ,'actuation.freq','actuation.ampl','actuation.offset'...
    ,'actuation.ampgrad','actuation.offsetgrad'});
% Assign zeros instead of NaN to make the data available across cases:
data.actuation_ampgrad(isnan(data.actuation_ampgrad)) = 0;
data.actuation_offsetgrad(isnan(data.actuation_offsetgrad)) = 0;

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PLOTS START HERE
%
%% Optimization convergence
plotConvergence(J)


%% Metrics for all cases
plotTargetMetric(dataALL.metrics_TI_mean, 0.2, 5)
plotTargetMetric(-dataALL.metrics_dudy_mean, 2.5, 5)
plotTargetMetric(-dataALL.metrics_dTIdy_mean, 0.2, 5)

%% Metrics for selected case
plotTargetMetric(data.metrics_TI_mean, 0.15, 5)
plotTargetMetric(-data.metrics_dudy_mean, 2.5, 5)
plotTargetMetric(-data.metrics_dTIdy_mean, 0.2, 5)


%% Display best / worst
[bestJ,ibest] = min(J);
[worstJ,iworst] = max(J);
fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    ibest, data.actuation_freq(ibest), data.actuation_ampl(ibest), data.actuation_offset(ibest), J(ibest), data.metrics_TI_mean(ibest));
fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    iworst, data.actuation_freq(iworst), data.actuation_ampl(iworst), data.actuation_offset(iworst), J(iworst), data.metrics_TI_mean(iworst));


%% Amplitude and TI relationship
plotMetricRelation(dataALL.actuation_ampl, dataALL.metrics_TI_mean, 'fit', true);
hold on, scatter(data.actuation_ampl, data.metrics_TI_mean, [], defaultOrange, 'filled')
xlabelg('amplitude: $$A$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Amplitude*freq and TI relationship
plotMetricRelation(dataALL.actuation_ampl.*dataALL.actuation_offset, dataALL.metrics_TI_mean, 'fit', true);
hold on, scatter(data.actuation_ampl.*data.actuation_offset, data.metrics_TI_mean, [], defaultOrange, 'filled')
xlabelg('amplitude: $$A$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Frequency and TI relationship
plotMetricRelation(stack_freq, stack_TI_mean);
hold on, scatter(freq, TI_mean, [], defaultOrange, 'filled')
xlabelg('frequency: $$f$$ [Hz]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Offset and TI relationship
plotMetricRelation(dataALL.actuation_offset, dataALL.metrics_TI_mean);
hold on, scatter(data.actuation_offset, data.metrics_TI_mean, [], defaultOrange, 'filled')
% hold on, scatter(offset, TI_mean, [], defaultOrange, 'filled')
xlabelg('offset: $$\theta$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Only last opt (TI grad)
R = corr([X Y],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:length(paramNames), length(paramNames)+1:length(paramNames)+length(metricNames)); % adjust if different sizes
corrTable = array2table(Rpm, 'RowNames', paramNames, 'VariableNames',metricNames);

% plot correlation table
figure('Name','Input–Output Correlation Table');
imagesc(Rpm);% show correlation values as color
axis equal tight;
colorRange = [      % red - white - green
    1.00  0.80  0.80
    1.00  0.88  0.88
    1.00  0.94  0.94
    1.00  0.97  0.97
    1.00  1.00  1.00
    0.97  1.00  0.97
    0.94  1.00  0.94
    0.88  1.00  0.88
    0.80  1.00  0.80];
colormap(colorRange);
clim([-1 1]);   % correlation range
colorbar;
% axes labels
set(gca, 'XTick', 1:numel(metricNames), 'XTickLabel', metricNames, ...
    'YTick', 1:numel(paramNames), 'YTickLabel', paramNames, ...
    'TickLabelInterpreter','none', 'XTickLabelRotation',45);
% xlabel('Input parameters'); ylabel('Output metrics');
ax = gca;
ax.FontSize = 16;
% title('Correlation between inputs and outputs');

% overlay numeric correlation values
for i = 1:size(Rpm,1)
    for j = 1:size(Rpm,2)
        val = Rpm(i,j);
        % overlay text
        text(j, i, sprintf('%.2f', val), ...
            'HorizontalAlignment','center', ...
            'FontSize',14);
    end
end


%% === CORRELATION ANALYSIS ===

% Combine all into one table for easy labeling
allNames = [paramNames, metricNames];
Z = [X, Y];

% Compute Pearson correlation
[Rp, Pp] = corr(Z, 'Rows','pairwise', 'Type','Pearson');
% Compute Spearman (rank) correlation
[Rs, Ps] = corr(Z, 'Rows','pairwise', 'Type','Spearman');

figure('Name','Pearson Correlation Matrix','Color','w');
heatmap(allNames, allNames, Rp, ...
    'Colormap', uColorMapClose, 'ColorLimits',[-1 1], ...
    'CellLabelColor','none');
title('Pearson Correlations (inputs + outputs)');
set(gca,"TickLabelInterpreter",'latex');

figure('Name','Spearman Correlation Matrix','Color','w');
heatmap(allNames, allNames, Rs, ...
    'Colormap', parula, 'ColorLimits',[-1 1], ...
    'CellLabelColor','none');
title('Spearman Correlations (inputs + outputs)');
set(gca,"TickLabelInterpreter",'latex');


%% Analyze weights
% targetWeight.J_TI = 0.5;
% targetWeight.J_hom_velgrad = 0.1;
% targetWeight.J_hom_TIgrad = 0.1;
% targetWeight.J_hom_CV = 0.1;
% targetWeight.J_aniso = 0.2;
% 
% for msi = 1:length(subDB)
%     % Individual components
%     subDB(msi).J_comp.J_TI
%     subDB(msi).J_comp.J_hom_velgrad
%     subDB(msi).J_comp.J_hom_TIgrad
%     subDB(msi).J_comp.J_hom_CV
%     subDB(msi).J_comp.J_aniso
% 
%     % Component weights
%     subDB(msi).weights.J_TI
%     subDB(msi).weights.J_hom_velgrad
%     subDB(msi).weights.J_hom_TIgrad
%     subDB(msi).weights.J_hom_CV
%     subDB(msi).weights.J_aniso
% 
%     % Visualize and reweight
% end

% 1. Initialize arrays to hold the raw component values
num_runs = length(subDB);
J_raw = zeros(num_runs, 5); % Columns: TI, velgrad, TIgrad, CV, aniso
W_old = zeros(num_runs, 5);

% Target theoretical weights
W_target = [0.5, 0.1, 0.1, 0.1, 0.2];

TI_target = 0.15;

% 2. Extract data from the struct array
for msi = 1:num_runs
    % Raw components
    J_raw(msi, 1) = ((subDB(msi).metrics.TI_mean - TI_target) / TI_target)^2;
    % J_raw(msi, 1) = subDB(msi).J_comp.J_TI;
    J_raw(msi, 2) = subDB(msi).J_comp.J_hom_velgrad^2;
    J_raw(msi, 3) = subDB(msi).J_comp.J_hom_TIgrad^2;
    J_raw(msi, 4) = subDB(msi).J_comp.J_hom_CV^2;
    J_raw(msi, 5) = subDB(msi).J_comp.J_aniso^2;
    
    % Old weights used
    W_old(msi, 1) = subDB(msi).weights.J_TI;
    W_old(msi, 2) = subDB(msi).weights.J_hom_velgrad;
    W_old(msi, 3) = subDB(msi).weights.J_hom_TIgrad;
    W_old(msi, 4) = subDB(msi).weights.J_hom_CV;
    W_old(msi, 5) = subDB(msi).weights.J_aniso;
end

% 3. Calculate Total J and Effective Weights for the old runs
% J_total = sum(W_i * J_i)
J_total_old = sum(J_raw .* W_old, 2); 

% Effective contribution percentage = (W_i * J_i) / J_total
Effective_Weights = (J_raw .* W_old) ./ J_total_old;
Mean_Effective_Weights = mean(Effective_Weights, 1);

disp('Average Effective Weights of previous runs:');
disp(Mean_Effective_Weights); 
% ^ Compare this output to your target: [0.5, 0.1, 0.1, 0.1, 0.2]
% You will likely see J_TI is far below 0.5.

% 4. Calculate Reweighting Factors (Normalization)
% Use the mean (or median) of the raw values across your database to find their typical scale
Scale_Factors = mean(J_raw, 1);

% The new weights should divide out the natural scale, then apply the target weight
W_new_unnormalized = W_target ./ Scale_Factors;

% Normalize so the new weights sum to 1 (optional, but keeps the total J scale consistent)
W_new = W_new_unnormalized / sum(W_new_unnormalized);

disp('Suggested New Applied Weights:');
disp(W_new);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PLOT ALL FLOW FIELDS
if plotPIV
    avgFields = {'U', 'V', 'TI', 'aniso', 'velgrad', 'TIgrad'};
    trFields  = {'u', 'v', 'vort'};

    currentpwd = pwd(); % Store for video generation

    %% =========================================================
    %  PHASE 1: PLOT AVERAGE FLOW FIELDS FOR ALL CASES
    %  =========================================================
    fprintf('Starting Phase 1: Average Flow Fields (Quick)...\n');
    figure(501); % Central figure handle reused by plotMeanField

    for msi = 1:length(subDB)
        % plotRootDir = subDB(msi).plotRootDir;
        caseID   = subDB(msi).caseID;
        iter     = subDB(msi).iteration;

        avgMaskNorm = []; % If you have a specific mask for this iteration, define it here

        % 0. LOAD AND PREPROCESS DATA
        pivDataDir = procPivDirFunc(subDB(msi).caseDir, iter);
        D = loadpiv(pivDataDir);

        x = D.x; y = D.y;
        u = D.u; v = D.v;

        % u(isnan(u)) = 0;
        % v(isnan(v)) = 0;

        % Dynamic cropping boundaries
        currentXRange = [min(x,[],'all') max(x,[],'all')];
        currentYRange = [min(y,[],'all') max(y,[],'all')];
        width = diff(currentXRange);
        height = diff(currentYRange);

        relCut = 0.05;
        xRange = [currentXRange(1)+relCut*width currentXRange(2)-relCut*width];
        yRange = [currentYRange(1)+relCut*height currentYRange(2)-relCut*height];

        % Crop all fields (vort not strictly needed for Phase 1, but keeps matrix sizes identical)
        [x_crop, y_crop, u_crop, v_crop, ~] = cropFields(xRange, yRange, x, y, u, v, D.vort);

        % Calculate turbulence metrics
        doPlotMetrics = false; % Suppress built-in plotting to use our custom exporter
        [metrics, fields] = turbulenceMetrics(u_crop, v_crop, x_crop, y_crop, doPlotMetrics);

        % Shift coordinates to start at 0
        x_crop = x_crop - x_crop(1);
        y_crop = y_crop - y_crop(1);
        xData = x_crop / L;
        yData = y_crop / L;

        % 1. PLOT AVERAGES
        for fIdx = 1:length(avgFields)
            fName = avgFields{fIdx};

            targetFolder = fullfile(plotRootDir, caseID, "flowfields", fName);
            ensureTopLevelFolder(targetFolder, plotRootDir);

            % Load variable directly from our fresh turbulenceMetrics output
            toplot = fields.(fName);

            opts = struct('nLevel', 40, 'cmap', 'jet');
            opts.cLabel = fName;
            opts.isLatex = true;
            opts.axisEqual = true;
            opts.customTicks = true;

            if strcmp(fName, 'U')
                meanU = mean(toplot(:), 'omitnan');
                toplot = toplot / meanU;
                opts.cLabel = '$$U / \bar{U}$$';
            elseif strcmp(fName, 'V')
                meanU = mean(toplot(:), 'omitnan');
                toplot = toplot / meanU;
                opts.cLabel = '$$V / \bar{U}$$';
            end
            opts.limits = [mean(toplot(:), 'omitnan') - 2*std(toplot(:), 'omitnan'), ...
                mean(toplot(:), 'omitnan') + 2*std(toplot(:), 'omitnan')];

            saveName = fullfile(targetFolder, sprintf('%s_%s.png', fName, mpt2str(iter)));
            plotMeanField(xData, yData, toplot, avgMaskNorm, opts, saveName);
        end
    end

    %% =========================================================
    %  PHASE 2: TIME RESOLVED PLOTS & VIDEO GENERATION
    %  =========================================================
    fprintf('Starting Phase 2: Time-Resolved Plots & Videos (This will take hours)...\n');
    fig = figure(502); % Use a new figure handle to avoid interfering with any residual Phase 1 states
    fig.Visible = 'on';

    for msi = 1:length(subDB)
        % plotRootDir = subDB(msi).plotRootDir;
        caseID   = subDB(msi).caseID;
        iter     = subDB(msi).iteration;

        avgMaskNorm = [];

        % 0. RELOAD DATA (Prevents Memory Overload)
        pivDataDir = procPivDirFunc(subDB(msi).caseDir, iter);
        D = loadpiv(pivDataDir, "extractAllVariables");

        x = D.x; y = D.y;
        u = D.u; v = D.v;
        vort = D.vort;
        corr = D.corr;
        uncU = D.uncU;
        uncV = D.uncV;

        % u(isnan(u)) = 0;
        % v(isnan(v)) = 0;

        % Re-calculate dynamic bounds
        currentXRange = [min(x,[],'all') max(x,[],'all')];
        currentYRange = [min(y,[],'all') max(y,[],'all')];
        width = diff(currentXRange);
        height = diff(currentYRange);

        relCut = 0.05;
        xRange = [currentXRange(1)+relCut*width currentXRange(2)-relCut*width];
        yRange = [currentYRange(1)+relCut*height currentYRange(2)-relCut*height];

        [x_crop, y_crop, u_crop, v_crop, vort_crop, corr_crop, uncU_crop, uncV_crop] = ...
            cropFields(xRange, yRange, x, y, u, v, vort, corr, uncU, uncV);

        x_crop = x_crop - x_crop(1);
        y_crop = y_crop - y_crop(1);
        xData = x_crop / L;
        yData = y_crop / L;

        % 2. TIME RESOLVED PLOTS & VIDEO
        for fIdx = 1:length(trFields)
            fName = trFields{fIdx};

            targetFolder = fullfile(plotRootDir, caseID, "flowfields", sprintf('%s_timeres', fName), sprintf('ms%.4d', iter));
            ensureTopLevelFolder(targetFolder, plotRootDir);

            opts = struct('nLevel', 100);
            opts.isLatex = true;
            opts.customTicks = true;
            opts.axisEqual = true;

            nFrames = size(u_crop, 3);

            switch fName
                case 'u'
                    toplot = u_crop / mean(u_crop(:), 'omitnan');
                    opts.cLabel = '$$U / \bar{U}$$';
                    opts.cmap = 'jet';
                case 'v'
                    toplot = v_crop / mean(u_crop(:), 'omitnan');
                    opts.cLabel = 'v';
                    opts.cmap = 'jet';
                case 'vort'
                    toplot = vort_crop;
                    opts.cLabel = 'vort';
                    opts.cmap = uColorMap;
            end
            opts.limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];

            % Initialize the plot with the first frame
            ax = axes(fig);

            % Ensure we get the specific Contour object handle
            [~, hContour] = contourf(ax, xData, yData, toplot(:,:,1), 100, 'LineStyle', 'none');

            colormap(ax, 'jet');
            clim(ax, opts.limits);
            cb = colorbar(ax);
            cb.Label.Interpreter = 'latex';
            ylabel(cb, opts.cLabel, 'Interpreter', 'latex');
            axis(ax, 'equal');

            % FRAME LOOP
            for iFrame = 1:nFrames

                clf(fig);
                ax = axes(fig);
                set(fig, 'Color', 'w'); % Sets the figure background to white
                [~, hContour] = contourf(ax, xData, yData, toplot(:,:,iFrame), 100, 'LineStyle', 'none');
                colormap(ax, 'jet');
                clim(ax, opts.limits);
                cb = colorbar(ax);
                cb.Label.Interpreter = 'latex';
                ylabel(cb, opts.cLabel, 'Interpreter', 'latex');
                axis(ax, 'equal');

                % If dot indexing fails, it's because hContour is likely a 'Contour' object
                % that requires 'set' or is not being returned as a scalar.

                % USE THE 'SET' FUNCTION (More compatible across MATLAB versions)
                % set(hContour, 'ZData', toplot(:,:,iFrame));
                % 
                % clim(ax, opts.limits);
                % 
                % title(ax, sprintf('Frame: %d', iFrame));

                set(fig, 'InvertHardcopy', 'off');

                saveName = fullfile(targetFolder, sprintf('%s_mpt%03d.png', fName, iFrame));

                % Changed '-image' to '-opengl' for better stability in loops
                print(fig, saveName, '-dpng', '-image', '-r300');

                if mod(iFrame, 50) == 0
                    drawnow;
                end
            end

            % 3. COMPILE VIDEO
            cd(targetFolder);
            videoCmd = sprintf('ffmpeg -framerate 5 -start_number 1 -i %s_mpt%%03d.png -c:v libx264 -preset fast -profile:v high -level:v 4.0 -pix_fmt yuv420p -crf 8 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" avideo5fps.avi', fName);
            system(videoCmd);
            cd(currentpwd);

        end
    end
end

