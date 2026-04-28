%% Script: train_and_evaluate_GPs.m
% Extracts data from optDB, trains GP models, and plots the results.
clear


%% Set up local file directories:
localPC = 1;
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\";
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2026_optimusPIV\fullOptimizations\";
end
dbFileName = fullfile(rootDataDir, 'optDB.mat');
load(dbFileName); % Load all the optimization data


%% Select cases based on date string:
all_caseIDs = string({optDB.caseID}); 
% Find all entries where the caseID starts with certain string
match_mask = startsWith(all_caseIDs, "20260424");
% Create the subset struct array
subDB = optDB(match_mask);
% subDB = optDB;


%% 1. Configuration and Data Extraction
% Define the keys exactly as they appear in optDB. 
% (Adjust 'meta.amplitude' to wherever your inputs actually live)
input_keys  = {'actuation.ampl', 'actuation.offset'}; 
output_keys = {'metrics.TI_mean', 'metrics.CV_U', 'metrics.CV_TI', 'metrics.aniso_mean'};
out_names   = {'TI', 'CV_U', 'CV_TI', 'Anisotropy'}; % Friendly names for plots

fprintf('Extracting data from database...\n');
X_struct = DB_extractData(subDB, input_keys);
Y_struct = DB_extractData(subDB, output_keys);

% Extract into matrices (DB_extractData converts '.' to '_')
X_raw = [X_struct.actuation_ampl, X_struct.actuation_offset];
Y_raw = [Y_struct.metrics_TI_mean, Y_struct.metrics_CV_U, ...
         Y_struct.metrics_CV_TI, Y_struct.metrics_aniso_mean];

% Clean the data (Remove rows where any input or output is NaN)
valid_idx = ~any(isnan(X_raw), 2) & ~any(isnan(Y_raw), 2);
X = X_raw(valid_idx, :);
Y = Y_raw(valid_idx, :);

fprintf('Using %d valid data points out of %d total.\n', size(X,1), size(X_raw,1));


%% 2. Train Gaussian Process Models
% We use Matern 5/2 kernel and standardize the inputs for stability.
models = cell(1, length(out_names));

fprintf('Training Gaussian Process Models...\n');
for i = 1:length(out_names)
    fprintf('  - Fitting %s ... ', out_names{i});
    % Fit the GP. 'OptimizeHyperparameters' tunes the model automatically.
    % To speed this up, you can remove 'OptimizeHyperparameters' and use default 'matern52'.
    models{i} = fitrgp(X, Y(:, i), ...
        'KernelFunction', 'matern52', ...
        'Standardize', true, ...
        'OptimizeHyperparameters', 'auto', ...
        'HyperparameterOptimizationOptions', ...
        struct('AcquisitionFunctionName', 'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 0));
    fprintf('Done.\n');
end


%% 3. Evaluate Models (Predicted vs Actual Parity Plots)
figure('Name', 'GP Model Quality', 'Position', [100, 100, 1000, 800]);
for i = 1:length(out_names)
    subplot(2, 2, i);
    
    % Get predictions on the training data
    Y_pred = predict(models{i}, X);
    Y_actual = Y(:, i);
    
    % Calculate R-squared (Goodness of Fit)
    SSres = sum((Y_actual - Y_pred).^2);
    SStot = sum((Y_actual - mean(Y_actual)).^2);
    R2 = 1 - (SSres / SStot);
    
    % Scatter plot
    scatter(Y_actual, Y_pred, 30, 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    
    % Ideal y=x line
    min_val = min([Y_actual; Y_pred]);
    max_val = max([Y_actual; Y_pred]);
    plot([min_val, max_val], [min_val, max_val], 'r--', 'LineWidth', 1.5);
    hold off;
    
    % Formatting
    title(sprintf('%s (R^2 = %.2f)', out_names{i}, R2));
    xlabel('Actual Measured Value');
    ylabel('GP Predicted Value');
    grid on; axis square;
end


%% 4. Visualize Response Surfaces
% Create a 2D grid of inputs to query the GP
nGrid = 50;
amp_range = linspace(min(X(:,1)), max(X(:,1)), nGrid);
off_range = linspace(min(X(:,2)), max(X(:,2)), nGrid);
[AmpGrid, OffGrid] = meshgrid(amp_range, off_range);
X_query = [AmpGrid(:), OffGrid(:)];

figure('Name', 'GP Response Surfaces', 'Position', [150, 150, 1200, 800]);
for i = 1:length(out_names)
    subplot(2, 2, i);
    
    % Predict Mean and standard deviation (uncertainty)
    [Y_pred, Y_sd] = predict(models{i}, X_query);
    
    % Reshape back to grid
    Z_pred = reshape(Y_pred, nGrid, nGrid);
    
    % Plot Surface
    surf(AmpGrid, OffGrid, Z_pred, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    hold on;
    
    % Overlay actual data points
    scatter3(X(:,1), X(:,2), Y(:, i), 40, 'k', 'filled', 'MarkerEdgeColor', 'w');
    hold off;
    
    % Formatting
    title(out_names{i});
    xlabel('Amplitude');
    ylabel('Offset');
    zlabel(out_names{i});
    colormap(parula);
    colorbar;
    view(-30, 45); % Nice 3D angle
    grid on;
end
