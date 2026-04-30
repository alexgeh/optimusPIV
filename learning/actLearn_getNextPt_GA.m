function [next_x, info] = actLearn_getNextPt_GA(models, input_defs, output_defs, AL_settings)
%% Select next active-learning point with a GA acquisition function.
%
% Inputs
%   models      : struct array from trainOutputModels in the main script
%   input_defs  : active input definitions only
%   output_defs : active output definitions only
%   AL_settings : active-learning settings from setup/main
%
% Output
%   next_x : vector in the active design/control space
%   info   : predicted acquisition diagnostics at next_x
%
% Exploration normalisation:
%   Each GP standard deviation is divided by the corresponding training
%   output scale (models(k).yScale). This prevents high-magnitude quantities
%   such as gradient slopes from dominating the exploration score only
%   because of units or variance.

    if isempty(models)
        error('actLearn_getNextPt_GA:NoModels', 'No trained models were supplied.');
    end

    lb = arrayfun(@(s) s.range(1), input_defs);
    ub = arrayfun(@(s) s.range(2), input_defs);
    nVars = numel(lb);

    options = optimoptions('ga', ...
        'Display', AL_settings.ga.Display, ...
        'PopulationSize', AL_settings.ga.PopulationBase + AL_settings.ga.PopulationPerVar*nVars, ...
        'MaxGenerations', AL_settings.ga.MaxGenerations, ...
        'UseParallel', AL_settings.ga.UseParallel);

    strategy = lower(AL_settings.current_strategy);
    switch strategy
        case 'explore'
            acqFun = @(x) -explorationScore(x, models); % GA minimizes
        case 'target'
            acqFun = @(x) targetCost(x, models, AL_settings) ...
                - AL_settings.target.explorationBonus .* explorationScore(x, models);
        otherwise
            error('Unknown active-learning strategy: %s', AL_settings.current_strategy);
    end

    next_x = ga(acqFun, nVars, [], [], [], [], lb, ub, [], options);

    info = struct();
    info.strategy = AL_settings.current_strategy;
    info.exploreScore = explorationScore(next_x, models);
    info.targetCost = targetCost(next_x, models, AL_settings);
end

function score = explorationScore(x, models)
    weightedTerms = [];
    weights = [];

    for k = 1:numel(models)
        [~, sigma] = predict(models(k).gp, x);
        scale = max(models(k).yScale, eps);
        w = models(k).exploreWeight;

        weightedTerms(end+1) = w .* (sigma ./ scale).^2; %#ok<AGROW>
        weights(end+1) = max(w, 0); %#ok<AGROW>
    end

    if isempty(weightedTerms) || sum(weights) <= 0
        score = 0;
    else
        % RMS-like score. This is less sensitive to the number of active
        % outputs than a raw sum, and every term is dimensionless.
        score = sqrt(sum(weightedTerms) ./ sum(weights));
    end
end

function cost = targetCost(x, models, AL_settings)
    cost = 0;

    for k = 1:numel(models)
        if strcmpi(models(k).role, 'diagnostic')
            continue
        end

        mu = predict(models(k).gp, x);
        scale = max(models(k).yScale, eps);
        target = getTarget(models(k), AL_settings);
        err = (mu - target) ./ scale;
        cost = cost + models(k).targetWeight .* err.^2;
    end
end

function target = getTarget(model, AL_settings)
    target = model.target;

    % Allow AL_settings.targets to override output_defs targets if you prefer
    % to keep targets grouped in one struct.
    if isfield(AL_settings, 'targets') && isstruct(AL_settings.targets)
        if isfield(AL_settings.targets, model.name)
            target = AL_settings.targets.(model.name);
        elseif strcmp(model.name, 'TI_mean') && isfield(AL_settings.targets, 'TI')
            target = AL_settings.targets.TI;
        end
    end
end
