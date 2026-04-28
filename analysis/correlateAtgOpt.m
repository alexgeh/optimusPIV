%% Find correlations between input parameters and turbulence metrics
%  Alexander Gehrke - 20251117
clear


%% Set analyze parameters
focusCase = 8;
L = 0.762;     % total top-to-bottom span in meters

variousColorMaps();

%% Load and select data
load('\\Files22.brown.edu\LRSResearch\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\optDB.mat'); % Full ATG optimization results data base
if focusCase == 1 % Homogenous, isotropic turbulence
    optID = 3;
    filtOptDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID)));
elseif focusCase == 2 % Velocity gradient
    optID = 6;
    filtOptDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID)));
elseif focusCase == 3 % Turbulence intensity gradient
    optID = 7;
    filtOptDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID)));
elseif focusCase == 4 % Combined: 1,2,3
    filtOptDB = [...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(3)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(6)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(7)));...
        ];
elseif focusCase == 5 % Velocity gradient (not converged)
    optID = 4;
    filtOptDB = DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(optID)));
elseif focusCase == 6 % All grad cases (but 5) stacked - run 5 hast very inconsistent results
    filtOptDB = [...
        ...DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(3)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(4)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(6)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(7)));...
        ];
elseif focusCase == 7 % All cases (but 5) stacked
    filtOptDB = [...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(3)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(4)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(6)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(7)));...
        ];
elseif focusCase == 8 % Lisbon 2026 data
    filtOptDB = [...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(3)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(4)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(6)));...
        DB_filterCases(optDB, 'caseID', @(d) endsWith(d, num2str(7)));...
        ];
end

data = DB_extractData(filtOptDB, {...
    'metrics.TI_mean','metrics.TIgrad_mean'...
    ,'metrics.dTIdy_mean','metrics.CV','metrics.velgrad_mean'...
    ,'metrics.dudy_mean','metrics.aniso_mean'...
    ,'actuation.freq','actuation.ampl','actuation.offset'...
    ,'actuation.ampgrad','actuation.offsetgrad'});

% Assign zeros instead of NaN to make the data available across cases:
data.actuation_ampgrad(isnan(data.actuation_ampgrad)) = 1e-32;
data.actuation_offsetgrad(isnan(data.actuation_offsetgrad)) = 1e-32;

% Calculate ampl & offset relative to sine function:
data.actuation_phiAmpl = data.actuation_ampl / 2;
data.actuation_phiZero = data.actuation_offset + data.actuation_ampl / 2;

% Physical gradients (deg/m)
data.actuation_dphiAmpl_dy = data.actuation_ampgrad ./ L;
data.actuation_dphiZero_dy = ( 2*data.actuation_offsetgrad + data.actuation_ampgrad ) ./ L;


%% Group by input (X) and output (Y):
X = [data.actuation_freq,data.actuation_phiAmpl,data.actuation_phiZero...
    ...,data.actuation_offset...
    ...,data.actuation_ampgrad,data.actuation_offsetgrad...
    ,data.actuation_dphiAmpl_dy,data.actuation_dphiZero_dy...
    ];
Y = [data.metrics_TI_mean,data.metrics_TIgrad_mean...
    ,data.metrics_CV,data.metrics_velgrad_mean...
    ,data.metrics_aniso_mean...
    ,data.metrics_dTIdy_mean...
    ,data.metrics_dudy_mean...
    ];
paramNames = {'$$f$$','$$\hat{\varphi}$$','$$\varphi_0$$'...
    ...,'alpha'...
    ...,'ampgrad','offsetgrad'...
    ,'$$d\hat{\varphi} / dy$$','$$d\varphi_0 / dy$$'...
    };
metricNames = {'$$\bar{TI}$$','$$\parallel \nabla TI \parallel$$'...
    ,'$$CV$$','$$\parallel \nabla U \parallel$$'...
    ,'$$A$$'...
    ,'$$dTI / dy$$'...
    ,'$$du / dy$$'...
    };

X_labels = paramNames;
Y_labels = metricNames;

%% Perform correlations
R = corr([X Y],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:length(paramNames), length(paramNames)+1:length(paramNames)+length(metricNames)); % adjust if different sizes
corrTable = array2table(Rpm, 'RowNames', paramNames, 'VariableNames',metricNames);

% plot correlation table
figure('Name','Input–Output Correlation Table');
imagesc(Rpm);% show correlation values as color
axis equal tight;
colorRange = brewermap(9, 'RdBu');
% colorRange = [      % red - white - green
%     1.00  0.80  0.80   
%     1.00  0.88  0.88
%     1.00  0.94  0.94
%     1.00  0.97  0.97
%     1.00  1.00  1.00   
%     0.97  1.00  0.97
%     0.94  1.00  0.94
%     0.88  1.00  0.88
%     0.80  1.00  0.80];
colormap(colorRange);  
clim([-1 1]);   % correlation range
cb = colorbar();
ylabel(cb, '$$r$$','FontSize',16)
cb.Label.Interpreter = 'latex';

% axes labels
set(gca, 'XTick', 1:numel(metricNames), 'XTickLabel', metricNames, ...
         'YTick', 1:numel(paramNames), 'YTickLabel', paramNames, ...
         'TickLabelInterpreter','none', 'XTickLabelRotation',45);
set(gca,"TickLabelInterpreter",'latex');
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


%% Linear relationship plots
%% dphiA/dy and dTIdy relationship
plotMetricRelation(data.actuation_dphiAmpl_dy, data.metrics_dTIdy_mean);
hold on, scatter(data.actuation_dphiAmpl_dy(111:end), data.metrics_dTIdy_mean(111:end), [], defaultOrange, 'filled')
xlabelg('$$d\hat{\varphi} / dy$$ [deg/m]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% dphiA/dy and dTIdy relationship
plotMetricRelation(data.metrics_dTIdy_mean, data.metrics_dudy_mean);
hold on, scatter(data.metrics_dTIdy_mean(111:end), data.metrics_dudy_mean(111:end), [], defaultOrange, 'filled')
xlabelg('$$d\hat{\varphi} / dy$$ [deg/m]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%%

%% --- Step 1: Build Data Matrix X and Output Y ---------------------------

% Example: replace these with your actual variables
TI       = data.metrics_TI_mean;
TIgrad   = data.metrics_TIgrad_mean;
dTIdy    = data.metrics_dTIdy_mean;
CV       = data.metrics_CV;
velgrad  = data.metrics_velgrad_mean;
dudy     = data.metrics_dudy_mean;
aniso    = data.metrics_aniso_mean;

f        = data.actuation_freq;
A        = data.actuation_ampl;
O        = data.actuation_offset;
Agrad    = data.actuation_ampgrad;
Ograd    = data.actuation_offsetgrad;
phiA     = data.actuation_phiAmpl;
phi0     = data.actuation_phiZero;
dphiA    = data.actuation_dphiAmpl_dy;
dphi0    = data.actuation_dphiZero_dy;


% Build input matrix X
% X = [f, A, O, Agrad, Ograd];
% X_labels = { ...
%     'freq', 'ampl', 'offset', 'amplGrad', 'offsetGrad'};

% Build input matrix X
X = [f, phiA, phi0, dphiA, dphi0];
X_labels = { ...
    'freq', 'phiAmpl', 'phiZero', 'dphiAmpl_dy', 'dphiZero_dy'};

% Choose your outputs of interest (can stack more)
Y = [TI, TIgrad, dTIdy, CV, velgrad, dudy, aniso];

Y_labels = { ...
    'TI', 'TIgrad', 'dTIdy', 'CV', 'velgrad', 'dudy', 'aniso'};


%%
% Normalize inputs if desired
% X = normalize(X); % uncomment if you prefer normalized correlations

% --- Step 2: Compute Correlations --------------------------------------

R_pearson  = corr([X Y], 'Type', 'Pearson');
R_spearman = corr([X Y], 'Type', 'Spearman');

% Combined labels for display
% all_labels = [X_labels, Y_labels];
all_labels = [X_labels, Y_labels];


% --- Step 3: Visualization ---------------------------------------------

% figure('Name','Correlation Heatmap (Pearson)','Color','w');
% heatmap(all_labels, all_labels, R_pearson);
% title('Pearson Correlation Matrix');
% 
% figure('Name','Correlation Heatmap (Spearman)','Color','w');
% heatmap(all_labels, all_labels, R_spearman);
% title('Spearman Correlation Matrix');

% --- Step 4: Scatter Matrix for Key Output -----------------------------

% Choose one or more target metrics to explore
% target_idx = find(strcmp(Y_labels,'$$du / dy$$')); % example: correlation to dU/dy
% target_idx = find(strcmp(Y_labels,'$$dTI / dy$$')); % example: correlation to dU/dy
% target_idx = find(strcmp(Y_labels,'$$\bar{TI}$$')); % example: correlation to dU/dy
target_idx = find(strcmp(Y_labels,'CV')); % example: correlation to dU/dy

figure('Name','Scatter Matrix to Target','Color','w');
plotmatrix([X Y(:,target_idx)]);
title('Scatter Matrix of Inputs vs selected target');


%%
% --- Prepare data -------------------------------------------------------
tbl = array2table([X Y], 'VariableNames', [X_labels, Y_labels]);

target = 'dTIdy';   % choose your output of interest
predictors = X_labels;

% --- Linear model (main effects only) -----------------------------------
formula = sprintf('%s ~ %s', target, strjoin(predictors, ' + '));
mdl_lin = fitlm(tbl, formula);

disp('==== Linear Model Summary ====')
disp(mdl_lin)


%% Interaction model: main effects + all pairwise
formula_int = sprintf('%s ~ (%s)^2', target, strjoin(predictors,' + '));
mdl_int = fitlm(tbl, formula_int);

disp('==== Interaction Model Summary ====')
disp(mdl_int)


%% Quadratic (square terms)
% formula_quad = sprintf('%s ~ poly(%s,2)', target, strjoin(predictors,','));
% mdl_quad = fitlm(tbl, formula_quad);
mdl_quad = fitlm(tbl, 'quadratic');

disp('==== Quadratic Model Summary ====')
disp(mdl_quad)


%%
figure('Color','w');
plot(mdl_lin.Fitted, tbl.(target), 'o'); hold on
plot(mdl_int.Fitted, tbl.(target), 'x');
plot(mdl_quad.Fitted, tbl.(target), '+');
legend('Linear','Interaction','Quadratic','Location','best');
xlabel('Predicted'); ylabel('True');
title(['Prediction Performance for ' target]);
grid on

%%
[coefSorted, idx] = sort(abs(mdl_int.Coefficients.Estimate(2:end)), 'descend');
namesSorted = mdl_int.CoefficientNames(idx+1);

disp('==== Dominant Coupled Effects ====')
table(namesSorted', coefSorted)


%%
y = dTIdy;   % your target vector
% X = [freq, phiAmpl, phiZero, dphiAmpl_dy, dphiZero_dy];
% X_labels = {'freq','phiAmpl','phiZero','dphiAmpl_dy','dphiZero_dy'};

% Generate quadratic and interaction features
X_inter = x2fx(X, 'interaction');  % includes linear, interactions, quadratics
X_inter(:,1) = []; % remove intercept column added by x2fx

% Linear names (5)
linNames = X_labels;

% Interaction names (nchoosek combinations, 10)
interNames = {};
idx = 1;
for i = 1:5
    for j = i+1:5
        interNames{idx} = sprintf('%s:%s', X_labels{i}, X_labels{j});
        idx = idx + 1;
    end
end

% Full list = 5 + 10 = 15
allNames = [linNames, interNames];

[B, FitInfo] = lasso(X_inter, y, 'CV', 10, 'PredictorNames', allNames);

bestModel = B(:, FitInfo.IndexMinMSE);

nz = find(bestModel ~= 0);
disp("Selected predictors:");
disp(FitInfo.PredictorNames(nz));
disp("Coefficients:");
disp(bestModel(nz));

lassoPlot(B, FitInfo, 'PlotType', 'Lambda', 'XScale', 'log');
title('LASSO Regularization Path');


[B, FitInfo] = lasso(X_inter, y,...
    'CV', 10, ...
    'PredictorNames', allNames, ...
    'Alpha', 0.5);   % 0.5 = balanced LASSO+Ridge
bestModel = B(:, FitInfo.IndexMinMSE);

nz = find(bestModel ~= 0);
disp("Selected predictors:");
disp(FitInfo.PredictorNames(nz));
disp("Coefficients:");
disp(bestModel(nz));




