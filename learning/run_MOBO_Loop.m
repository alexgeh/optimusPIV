%% Script: run_MOBO_Loop.m
% Runs a Multi-Objective Genetic Algorithm on the trained GP surrogates.

% NEEDS train_and_evaluate_GPs.m TO BE RAN PRIOR!


%% 1. Configuration
target_TI = 0.12; % Set your target TI here!
kappa = 1.0;      % Exploration factor (Higher = prefers highly uncertain areas)

% Define bounds for the Genetic Algorithm based on your previous data
% lb = [min_Amplitude, min_Offset], ub = [max_Amplitude, max_Offset]
lb = min(X); 
ub = max(X); 

fprintf('Starting Multi-Objective GA for Target TI = %.3f...\n', target_TI);

%% 2. Define the Multi-Objective Function
% The GA passes a matrix of populations, so we wrap the objective function
% to handle multiple rows of inputs at once.
obj_fun = @(x) eval_surrogate_objectives(x, models, target_TI, kappa);

%% 3. Run gamultiobj
options = optimoptions('gamultiobj', ...
    'PopulationSize', 300, ...
    'MaxGenerations', 200, ...
    'Display', 'iter', ...
    'PlotFcn', @gaplotpareto); % Automatically plots the Pareto front

% Run the genetic algorithm
% Output: pareto_X (the motor configs), pareto_Y (the objective scores)
[pareto_X, pareto_Y] = gamultiobj(obj_fun, 2, [], [], [], [], lb, ub, [], options);

%% 4. Analyze and Select the Best Candidate
% Objective 1 is the TI Error. Objective 2 is the Imperfection Score.
TI_errors = pareto_Y(:, 1);
Quality_penalties = pareto_Y(:, 2);

% Find the point that perfectly hits the TI target (minimum TI error)
[~, best_TI_idx] = min(TI_errors);
best_config_for_TI = pareto_X(best_TI_idx, :);

% Find a "Balanced" point (e.g., willing to accept slightly worse TI for much better homogeneity)
% We normalize the scores to find the point closest to the "Utopia Point" (0,0)
norm_TI = TI_errors / max(TI_errors);
norm_Qual = Quality_penalties / max(Quality_penalties);
distance_to_utopia = sqrt(norm_TI.^2 + norm_Qual.^2);
[~, balanced_idx] = min(distance_to_utopia);
balanced_config = pareto_X(balanced_idx, :);

fprintf('\n=== OPTIMIZATION RESULTS ===\n');
fprintf('To get exactly TI = %.3f (Best TI Accuracy):\n', target_TI);
fprintf('  Amplitude = %.2f, Offset = %.2f\n', best_config_for_TI(1), best_config_for_TI(2));
fprintf('  -> Predicted Penalty Score: %.4f\n\n', Quality_penalties(best_TI_idx));

fprintf('For the Best Balanced Trade-off (Good TI + High Quality Flow):\n');
fprintf('  Amplitude = %.2f, Offset = %.2f\n', balanced_config(1), balanced_config(2));
fprintf('  -> Predicted TI Error: %.4f\n', TI_errors(balanced_idx));
fprintf('  -> Predicted Penalty Score: %.4f\n', Quality_penalties(balanced_idx));


%% --- Helper Function for the Surrogate Objectives ---
function Y_obj = eval_surrogate_objectives(x, models, target_TI, kappa)
    % Preallocate output [Number of points x 2 Objectives]
    N = size(x, 1);
    Y_obj = zeros(N, 2);
    
    % Predict mean (mu) and standard deviation (sigma) for all 4 models
    % models{1}: TI, models{2}: CV_U, models{3}: CV_TI, models{4}: Aniso
    [mu_TI, sig_TI]       = predict(models{1}, x);
    [mu_CV_U, sig_CV_U]   = predict(models{2}, x);
    [mu_CV_TI, sig_CV_TI] = predict(models{3}, x);
    [mu_Aniso, sig_Aniso] = predict(models{4}, x);
    
    % OBJECTIVE 1: Target TI Error
    % We want to minimize the absolute difference.
    % We subtract kappa * sigma to reward the optimizer for exploring uncertain areas.
    TI_error_mean = abs(mu_TI - target_TI);
    Obj1 = TI_error_mean - (kappa * sig_TI);
    
    % OBJECTIVE 2: Flow Imperfection (Minimize CVs and Anisotropy)
    % Sum the means, and subtract the sum of uncertainties (Exploration)
    imperfection_mean = mu_CV_U + mu_CV_TI + mu_Aniso;
    imperfection_sig  = sig_CV_U + sig_CV_TI + sig_Aniso;
    Obj2 = imperfection_mean - (kappa * imperfection_sig);
    
    % Ensure objectives don't go artificially negative due to kappa
    Y_obj(:, 1) = max(Obj1, 0);
    Y_obj(:, 2) = max(Obj2, 0);
end
