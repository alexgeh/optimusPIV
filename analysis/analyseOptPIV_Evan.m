%% Script to analyze ATG PIV optimization
%#ok<*SAGROW> 
clear

optID = 3;
switch optID
    case 3 % Synchronous ATG control - TI_target = 0.2, homogenous, isotropic
        projStr = "20251017_ATG_bayes_opt_3";
        xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
        yRange = [-0.0650 0.1396];
        nPlotFrames = 200;
    % Cases 4,5,6:
    % Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient
    case 4 % !! LAST 10 PIV FRAMES FAULTY !! -> optim. not usable -> needs to be reprocessed !!
        projStr = "20251022_ATG_bayes_opt_4";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190; % LAST 10 FRAMES NOT ILLUMINATED
    case 5 % !! DID NOT CONVERGE !! -> optim. not usable
        projStr = "20251022_ATG_bayes_opt_4";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    case 6 % succesful run of "Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient"
        projStr = "20251023_ATG_bayes_opt_6";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    case 7 % Gradient ATG control - TI_target = 0.2, dTIdy = -0.2, min vel gradient
        projStr = "20251024_ATG_bayes_opt_7";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    otherwise
        error('opt ID not found - cannot continue')
end

if ismac
    projDir = fullfile("/Volumes/LRSResearch/ENG_Breuer_Shared/group/optimusPIV/DATA", projStr);
    plotDir = fullfile("/Volumes/LRSResearch/ENG_Breuer_Shared/group/optimusPIV/PLOTS", projStr);
    pivFolder = fullfile(projDir, "proc_PIV");
else

    projDir = fullfile("R:\ENG_Breuer_Shared","group","optimusPIV","DATA", projStr);
    plotDir = fullfile("R:\ENG_Breuer_Shared\group\optimusPIV\PLOTS\", projStr);
    pivFolder = fullfile(projDir, "proc_PIV");
end

load(fullfile(projDir, "workspaceOptimization.mat"))

% variousColorMaps();

%% Extract and relabel data
J = [optResults.J];
freq = [optResults.freq];
alpha = [optResults.alpha];
relBeta = [optResults.relBeta];
ampl = [optResults.ampl];
offset = [optResults.offset];

nIter = length(J);
for iter = 1:nIter
    J_TI(iter) = optResults(iter).J_comp.J_TI; 
    if optID == 3
        J_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
    elseif optID == 4 || optID == 5 || optID == 6 || optID == 7
        J_hom_dUdy(iter) = optResults(iter).J_comp.J_hom_dUdy;
    end
    J_hom_TIgrad(iter) = optResults(iter).J_comp.J_hom_TIgrad;
    J_hom_CV(iter) = optResults(iter).J_comp.J_hom_CV;
    J_aniso(iter) = optResults(iter).J_comp.J_aniso;
    
    TI_mean(iter) = optResults(iter).metrics.TI_mean;
    TI_std(iter) = optResults(iter).metrics.TI_std;
    TIgrad_mean(iter) = optResults(iter).metrics.TIgrad_mean;
    TIgrad_std(iter) = optResults(iter).metrics.TIgrad_std;
    CV(iter) = optResults(iter).metrics.CV; % coefficient of variation
    velgrad_mean(iter) = optResults(iter).metrics.velgrad_mean;
    aniso_mean(iter) = optResults(iter).metrics.aniso_mean;
end

%% best & worst
[bestJ,ibest] = min(J);
[worstJ,iworst] = max(J);

fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    ibest, freq(ibest), ampl(ibest), offset(ibest), J(ibest), TI_mean(ibest));
fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    iworst, freq(iworst), ampl(iworst), offset(iworst), J(iworst), TI_mean(iworst));


%% correlations (params vs metrics)
inputData = [freq', ampl', offset', alpha', relBeta'];
if optID == 3
    outputData = [J_TI', J_velgrad', J_hom_TIgrad', J_hom_CV', J_aniso', J', TI_mean'];
elseif optID == 4
    outputData = [J_TI', J_hom_dUdy', J_hom_TIgrad', J_hom_CV', J_aniso', J', TI_mean'];
end
paramNames = {'freq','ampl','offset','alpha','relBeta'};
metricNames = {'J_TI','J_velgrad','J_hom_TIgrad','J_hom_CV','J_aniso','J_tot','TI_mean'};

R = corr([inputData outputData],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:length(paramNames), length(paramNames)+1:length(paramNames)+length(metricNames)); % adjust if different sizes
corrTable = array2table(Rpm, 'RowNames', paramNames, 'VariableNames',metricNames);

%% correlation table

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
xlabel('Input parameters'); ylabel('Output metrics');
title('Correlation between inputs and outputs');

% overlay numeric correlation values
for i = 1:size(Rpm,1)
    for j = 1:size(Rpm,2)
        val = Rpm(i,j);
        % overlay text
        text(j, i, sprintf('%.2f', val), ...
            'HorizontalAlignment','center', ...
            'FontSize',9);
    end
end

%%




% % %% scatter plots of A vs the main metrics
% % figure('Name', 'Amplitude vs main metrics');
% % subplot(2,2,1); scatter(ampl, TI_mean, 20, 'filled'); xlabel('Amplitude (deg)'); ylabel('TI\_mean'); grid on
% % subplot(2,2,2); scatter(ampl, J_hom_CV, 20, 'filled'); xlabel('Amplitude'); ylabel('J\_CV'); grid on
% % subplot(2,2,3); scatter(ampl, J_aniso, 20, 'filled'); xlabel('Amplitude'); ylabel('J\_aniso'); grid on
% % subplot(2,2,4); scatter(ampl, J, 20, 'filled'); xlabel('Amplitude'); ylabel('J\_total'); grid on

%% scatter plots of A vs the physical metrics
figure('Name', 'Amplitude vs select physical metrics');
subplot(2,2,1); scatter(ampl, TI_mean, 20, 'filled'); xlabel('Amplitude (deg)'); ylabel('TI\_mean'); grid on
subplot(2,2,2); scatter(ampl, CV, 20, 'filled'); xlabel('Amplitude'); ylabel('CV'); grid on
subplot(2,2,3); scatter(ampl, velgrad_mean, 20, 'filled'); xlabel('Amplitude'); ylabel('velgrad\_mean'); grid on
subplot(2,2,4); scatter(ampl, aniso_mean, 20, 'filled'); xlabel('Amplitude'); ylabel('aniso\_mean'); grid on

% scatter plots of frequency vs the main metrics
figure('Name', 'Frequency vs main metrics');
subplot(2,2,1); scatter(freq, TI_mean, 20, 'filled'); xlabel('Frequency'); ylabel('TI\_mean'); grid on
subplot(2,2,2); scatter(freq, J_hom_CV, 20, 'filled'); xlabel('Frequency'); ylabel('J\_CV'); grid on
subplot(2,2,3); scatter(freq, J_aniso, 20, 'filled'); xlabel('Frequency'); ylabel('J\_aniso'); grid on
subplot(2,2,4); scatter(freq, J, 20, 'filled'); xlabel('Frequency'); ylabel('J\_total'); grid on




%% Make Model Table
modelTable = linearModelMapper(inputData, outputData, paramNames,metricNames)


return


%% linear regression (TI_mean ~ params)
T = table(freq(:), ampl(:), offset(:), TI_mean(:), 'VariableNames',{'freq','ampl','offset','TI_mean'});
lm = fitlm(T,'TI_mean~freq+ampl+offset');
disp(lm);
% for J_CV
T2 =table(freq(:), ampl(:), offset(:), J_hom_CV(:), 'VariableNames',{'freq','ampl','offset','J_hom_CV'});
lm2 = fitlm(T2,'J_hom_CV ~ freq + ampl + offset');
disp(lm2);


%% Pareto / trade-off plots: TI vs homogeneity vs anisotropy
figure;
scatter(TI_mean, J_CV, 40, A, 'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_CV');
title('TI vs CV (color=A)');
% mark target TI
xline(0.2,'r--','Target TI');
% also plot TI vs J_aniso
figure;
scatter(TI_mean, J_aniso, 40, A, 'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_aniso');
title('TI vs anisotropy (color=A)');
xline(0.2,'r--','Target TI');







%% Dominance / Pareto check
%  Example for just J_TI, J_CV, J_aniso
P = pareto_bool([J_TI, J_CV, J_aniso]);
sum(P) % number of Pareto-efficient points

function isPareto = pareto_bool(objs)
% objs: N x K matrix (minimize each column)
N = size(objs,1);
isPareto = true(N,1);
for i=1:N
    for j=1:N
        if all(objs(j,:) <= objs(i,:)) && any(objs(j,:) < objs(i,:))
            isPareto(i) = false;
            break;
        end
    end
end
end


%% linearModelMapper Function
%function should compute the linear model fit for each possible combination of
%input variables to each output variable
% Output is a table with model fits for all combinations of input vars for
% each output var
function modelTable = linearModelMapper(inputData, outputData, paramNames, metricNames)
%inputData and outputData are tables of the data exported from optResults
    
    modelTable = {};

for d_out = 1:size(outputData,2)
    d_outname = metricNames{d_out};

    for k = 1:size(inputData,2)
        subsets = nchoosek(1:size(inputData,2), k);

        for i = 1:size(subsets,1)
            % input_subset = inputData(:,subsets(i,:));
            % equation = sprintf('%s~%s', d_outname,strjoin({paramNames{:,subsets(i,:)}},'+'));
            % 
            % mdl = fitlm(input_subset,equation);
            % fprintf('%s\n', equation)
            idx        = subsets(i,:);                 % predictor column indices
            predNames  = paramNames(idx);              % predictor names (cellstr)
            rhs        = strjoin(predNames,' + ');
            eqn        = sprintf('%s ~ %s', d_outname, rhs);

            % Build a table that includes BOTH predictors and the named response
            Tout = array2table([inputData(:,idx) outputData(:,d_out)], ...
                   'VariableNames', [predNames {d_outname}]);

            mdl = fitlm(Tout, eqn);                   
            anovaTbl = anova(mdl,'summary');

            modelTable{end+1,1} = eqn;
            modelTable{end,2} = mdl;
            modelTable{end,3} = anovaTbl;
        end
    end
end
modelTable = cell2table(modelTable, ...
        'VariableNames', {'formula','mdl','anovaTbl'});
end