%% Script: run_NDim_Pareto_Optimization.m
% Runs a 4-Objective Genetic Algorithm to find the true trade-off surface.

%% 1. Configuration
target_TI = 0.125; % The TI you want to achieve
lb = min(X);      % Lower bounds from your training data [Amp, Offset]
ub = max(X);      % Upper bounds

% We define 4 Objectives:
% 1. TI Error | 2. CV_U | 3. CV_TI | 4. Anisotropy
n_obj = 4;

%% 2. Run Multi-Objective GA
options = optimoptions('gamultiobj', ...
    'PopulationSize', 400, ...  % Increased for higher dimensional search
    'MaxGenerations', 150, ...
    'SelectionFcn', @selectiontournament, ...
    'Display', 'iter');

fprintf('Running 4D Pareto Optimization...\n');
% obj_fun_ndim is defined below
[pareto_X, pareto_Y] = gamultiobj(@(x) obj_fun_ndim(x, models, target_TI), ...
                                 size(lb,2), [], [], [], [], lb, ub, [], options);

%% 3. Post-Optimization Selection (The "Decision Maker")
% pareto_Y is [N x 4]. Columns: [TI_Err, CV_U, CV_TI, Aniso]

% Strategy: Find the configuration that hits the TI target within 2% 
% and THEN has the best combined homogeneity.
ti_tolerance = 0.02 * target_TI; 
candidates_mask = pareto_Y(:,1) < ti_tolerance;

if any(candidates_mask)
    valid_configs = pareto_X(candidates_mask, :);
    valid_metrics = pareto_Y(candidates_mask, :);
    
    % Within these "good TI" candidates, find the one with the lowest CV_U
    [~, best_idx] = min(valid_metrics(:, 2)); 
    
    final_config = valid_configs(best_idx, :);
    final_scores = valid_metrics(best_idx, :);
    
    fprintf('\n--- RECOMMENDED CONFIGURATION ---\n');
    fprintf('Amplitude: %.3f | Offset: %.3f\n', final_config(1), final_config(2));
    fprintf('Predicted Results:\n');
    fprintf('  TI Error:   %.4f\n', final_scores(1));
    fprintf('  CV_U:       %.4f\n', final_scores(2));
    fprintf('  CV_TI:      %.4f\n', final_scores(3));
    fprintf('  Anisotropy: %.4f\n', final_scores(4));
else
    fprintf('No configurations found hitting the TI target. Try increasing population size.\n');
end

%% 4. Visualization (2D Projections)
% Since we can't see 4D, we plot the trade-off between TI Error and CV_U
figure('Name', 'Pareto Projection: TI vs Homogeneity');
scatter(pareto_Y(:,1), pareto_Y(:,2), 30, pareto_Y(:,4), 'filled');
xlabel('TI Absolute Error');
ylabel('CV_U (Velocity Homogeneity)');
title('4D Pareto Set (Color = Anisotropy)');
colorbar; grid on;

%% --- N-Dimensional Objective Function ---
function out = obj_fun_ndim(x, models, target_TI)
    % x can be a matrix of individuals
    N = size(x, 1);
    out = zeros(N, 4);
    
    % Query all models (Independent GPs)
    mu_TI    = predict(models{1}, x);
    mu_CVU   = predict(models{2}, x);
    mu_CVTI  = predict(models{3}, x);
    mu_Aniso = predict(models{4}, x);
    
    % Return the 4 objectives as a vector for each individual
    out(:, 1) = abs(mu_TI - target_TI); % Obj 1: TI Accuracy
    out(:, 2) = mu_CVU;                 % Obj 2: Velocity Homogeneity
    out(:, 3) = mu_CVTI;                % Obj 3: TI Homogeneity
    out(:, 4) = mu_Aniso;               % Obj 4: Anisotropy
end
