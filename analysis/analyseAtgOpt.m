%% Script to analyze ATG PIV optimization
%#ok<*SAGROW> 
clear


%% Processing parameters:
localPC = 1; % 1: office PC, 2: Legion (laptop)
optID = 7; % Specific case to look at
plotPIV = false; % Plot PIV - !! Will take VEEERY long !!
% L = 0.123; % Characteristic length [m], diagonal length of panels
L = 0.087; % Characteristic length [m], width of panels

% Set up local file directories:
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\";
    plotDir = fullfile("R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\");
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2025_optimusPIV\fullOptimizations\";
    plotDir = fullfile("C:\Users\alexg\Downloads\TMPDATA_2025_optimusPIV\plots\");
end
load(fullfile(rootDataDir, 'optDB.mat')); % Load all the optimization data
variousColorMaps(); % Colors and colormaps
subDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID))); % Secondary data base only for one case


%% Extract parameters and quantities
J = DB_extractData(subDB, 'J');
data = DB_extractData(optDB, {...
    'metrics.TI_mean','metrics.TIgrad_mean'...
    ,'metrics.dTIdy_mean','metrics.CV','metrics.velgrad_mean'...
    ,'metrics.dudy_mean','metrics.aniso_mean'...
    ,'actuation.freq','actuation.ampl','actuation.offset'...
    ,'actuation.ampgrad','actuation.offsetgrad'});
% Assign zeros instead of NaN to make the data available across cases:
data.actuation_ampgrad(isnan(data.actuation_ampgrad)) = 0;
data.actuation_offsetgrad(isnan(data.actuation_offsetgrad)) = 0;
% Group by input (X) and output (Y):
X = [data.actuation_freq,data.actuation_ampl,data.actuation_offset...
    ,data.actuation_ampgrad,data.actuation_offsetgrad];
Y = [data.metrics_TI_mean,data.metrics_TIgrad_mean,data.metrics_dTIdy_mean...
    ,data.metrics_CV,data.metrics_velgrad_mean,data.metrics_dudy_mean...
    ,data.metrics_aniso_mean];
paramNames = {'freq','ampl','offset','ampgrad','offsetgrad'};
metricNames = {'TI_mean','TIgrad_mean','dTIdy_mean','CV','velgrad_mean',...
    'dudy_mean','aniso_mean'};


%% Optimization convergence
plotConvergence(J)


%%
plotTargetMetric(data.metrics_TI_mean, 0.2, 5)
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
plotMetricRelation(data.actuation_ampl, data.metrics_TI_mean, 'fit', true);
% hold on, scatter(ampl, TI_mean, [], defaultOrange, 'filled')
xlabelg('amplitude: $$A$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14; 


%% Frequency and TI relationship
plotMetricRelation(stack_freq, stack_TI_mean);
hold on, scatter(freq, TI_mean, [], defaultOrange, 'filled')
xlabelg('frequency: $$f$$ [Hz]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Offset and TI relationship
plotMetricRelation(stack_offset, stack_TI_mean);
hold on, scatter(offset, TI_mean, [], defaultOrange, 'filled')
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

figure('Name','Spearman Correlation Matrix','Color','w');
heatmap(allNames, allNames, Rs, ...
    'Colormap', parula, 'ColorLimits',[-1 1], ...
    'CellLabelColor','none');
title('Spearman Correlations (inputs + outputs)');




