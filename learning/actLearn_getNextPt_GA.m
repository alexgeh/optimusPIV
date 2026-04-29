function next_params = actLearn_getNextPt_GA(models, config, strategy, target_vals)
    % models: cell array of trained GP models
    % strategy: 'explore' or 'target'
    % target_vals: struct containing target metrics (e.g. target_vals.TI = 0.1)

    % Define bounds from config (extendable to 10-15 dims)
    lb = [config.OPT_settings.alphaRange(1), config.OPT_settings.relBetaRange(1)];
    ub = [config.OPT_settings.alphaRange(2), config.OPT_settings.relBetaRange(2)];
    nVars = length(lb);

    % GA Options (Kept your original scaling logic)
    options = optimoptions('ga', ...
        'Display', 'off', ...
        'PopulationSize', 80 + 10*nVars, ... 
        'MaxGenerations', 100);

    % CHANGE 1: Calculate normalization scales for exploration
    % Reason: Anisotropy (~1.0) has a much larger variance than TI (~0.1). 
    % Without this, the GA will only explore to reduce Anisotropy uncertainty.
    norm_scales = zeros(1, length(models));
    for m = 1:length(models)
        norm_scales(m) = std(models{m}.Y); 
    end

    % Acquisition Function
    if strcmp(strategy, 'explore')
        % Objective: MAXIMIZE normalized uncertainty
        acq_fun = @(x) -sum(cellfun(@(m, scale) select_norm_sigma(m, x, scale), models, num2cell(norm_scales)));
    else
        % Objective: MINIMIZE distance to target
        % (Assuming acquisition_target_logic is defined below as you had it)
        acq_fun = @(x) acquisition_target_logic(x, models, target_vals);
    end

    % Run GA
    next_params = ga(acq_fun, nVars, [], [], [], [], lb, ub, [], options);
end

% CHANGE 2: Helper to get normalized sigma
function norm_s = select_norm_sigma(model, x, scale)
    [~, s] = predict(model, x);
    norm_s = s / scale;
end

function cost = acquisition_target_logic(x, models, targets)
    % Predict metrics for this candidate point
    mu_TI    = predict(models{1}, x);
    mu_CVU   = predict(models{2}, x);
    mu_CVTI  = predict(models{3}, x);
    mu_Aniso = predict(models{4}, x);
    
    % Normalized error from target (Assuming targets is a scalar TI value based on your main script call)
    % If targets is a struct, use targets.TI. If it's a scalar, just use targets.
    if isstruct(targets), t_val = targets.TI; else, t_val = targets; end
    
    err_TI   = (abs(mu_TI - t_val) / t_val)^2;
    pen_CVU  = mu_CVU;    
    pen_CVTI = mu_CVTI;   
    pen_Aniso = mu_Aniso; 
    
    cost = 1.0 * err_TI + 0.5 * pen_CVU + 0.2 * pen_CVTI + 0.2 * pen_Aniso;
end
