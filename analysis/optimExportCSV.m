%% Script to export optimization results to CSV for plotting
%  Alexander Gehrke - 20251231
%#ok<*SAGROW>

clear
close all


%% Processing parameters:
localPC = 1; % 1: office PC, 2: Legion (laptop)
optID = [3,6,7]; % Specific case(s) to look at
plotPIV = false; % Plot PIV - !! Will take VEEERY long !!
% L = 0.123; % Characteristic length [m], diagonal length of panels
L = 0.087; % Characteristic length [m], width of panels
yRange = [-0.111 0.137]; % PIV FOV y dimensions [m]

% Set up local file directories:
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\";
    outDir = fullfile("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\2026_Lisbon_Symposium\datfiles\");
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2025_optimusPIV\fullOptimizations\";
    outDir = fullfile("C:\Users\alexg\Downloads\TMPDATA_2026_Lisbon_Symposium\datfiles\");
end
load(fullfile(rootDataDir, 'optDB.mat')); % Load all the optimization data
variousColorMaps(); % Colors and colormaps

caseColor(:,3) = [27,158,119] / 255;
caseColor(:,6) = [217,95,2] / 255;
caseColor(:,7) = [117,112,179] / 255;

caseColorPale(:,3) = [127,201,127] / 255;
caseColorPale(:,6) = [190,174,212] / 255;
caseColorPale(:,7) = [253,192,134] / 255;

% figure(7456); semilogy(0,0);

%% Extract parameters and quantities
for optIdx = optID
    subDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optIdx))); % Secondary data base only for one case
    
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


    %% Display best / worst
    [bestJ,ibest] = min(J);
    [worstJ,iworst] = max(J);
%     fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
%     ibest, data.actuation_freq(ibest), data.actuation_ampl(ibest), data.actuation_offset(ibest), J(ibest), data.metrics_TI_mean(ibest));
%     fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
%     iworst, data.actuation_freq(iworst), data.actuation_ampl(iworst), data.actuation_offset(iworst), J(iworst), data.metrics_TI_mean(iworst));
    J_norm_one = (J - min(J)) / (J(1) - min(J));
    J_norm_max = (J - min(J)) / (max(J) - min(J));
    

    %% Optimization convergence
%     plotConvergence(J_norm_max);
    plotConvergence(J_norm_max, ...
        'AllColor', caseColorPale(:,optIdx), ...
        'ImpColor', caseColor(:,optIdx));
    ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;

    
    %% Flowfield profiles
    yRangeArray = linspace(0,yRange(2)-yRange(1),length(mean(subDB(1).fields.U,2))) / L;
    yMinToMax = [yRangeArray(1), yRangeArray(end)];
    yHeight = yRange(2)-yRange(1);

    U_mean = mean(subDB(ibest).fields.U,'all');
    dUdy_mean = mean(subDB(ibest).fields.dUdy,'all') / U_mean;
    dUdy_Delta = dUdy_mean*yHeight/2;


    %% Velocity profiles
    figure(852); hold on;
    toplot = mean(subDB(ibest).fields.U,2) / U_mean;
    plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', 'black');
    plot(yRangeArray, toplot, "LineWidth", 2, 'Color', caseColor(:,optIdx));
    xlabelg("$$y / L$$"); ylabelg("$$U / \bar{U}$$");
    xlim(yMinToMax);
    box on
    ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;


    %% TI profiles
    figure(4916); hold on;
    toplot = mean(subDB(ibest).fields.TI,2);
    toplot = toplot - mean(toplot);
    plot(yRangeArray, toplot, "LineWidth", 2, 'Color', caseColor(:,optIdx));
    % plot(yMinToMax, TI_target*ones(2,1), "LineWidth", 1, 'Color', 'black');
    plot(yMinToMax, mean(toplot)*ones(2,1), '-', "LineWidth", 1, 'Color', 'black');
    xlabelg("$$y / L$$"); ylabelg("$$TI - \overline{TI}_{target}$$");
    xlim(yMinToMax);
    % ylim([0 0.35]); yticks(0:0.1:0.4);
    box on
    ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;

end

figure(7456);
lgd = legend('','hom. isotropic','','','U gradient','','','TI gradient');
fontsize(lgd,12,'points')



