function [next_x, info] = actLearn_getNextPt_GA(models, input_defs, output_defs, AL_settings, X_existing)
%% Select next active-learning point with a GA acquisition function.
%
% Inputs
%   models      : struct array from active-learning GP training
%                 Each model is trained on NORMALISED input coordinates.
%   input_defs  : active input definitions only
%   output_defs : active output definitions only (kept for interface stability)
%   AL_settings : active-learning settings from setup/main
%   X_existing  : existing samples in PHYSICAL/DESIGN coordinates, size n x d
%
% Output
%   next_x : vector in the active physical/design-control space
%   info   : predicted acquisition diagnostics at next_x
%
% Strategy = 'explore':
%   maximise equal normalised GP uncertainty across outputs, multiplied by
%   an adaptive anti-clustering penalty.
%
% Strategy = 'target':
%   minimise targetCost.m, a soft feasibility-first cost that prioritises
%   target matching before minimising lower-is-better penalty metrics.

    %#ok<INUSD> % output_defs is kept for backwards-compatible interface clarity

    if nargin < 5
        X_existing = [];
    end

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

    X_existing_N = actLearn_normalizeInputs(X_existing, input_defs);
    antiClusterScale = estimateAntiClusterScale(X_existing_N, AL_settings);

    strategy = lower(AL_settings.current_strategy);
    switch strategy
        case 'explore'
            % GA minimizes, so return negative score.
            acqFun = @(x) -explorationScore(x, models, input_defs, X_existing_N, antiClusterScale, AL_settings);

        case 'target'
            % GA minimizes targetCost. A small exploration bonus can be kept,
            % but should normally be zero for the first targeted tests.
            explorationBonus = getTargetExplorationBonus(AL_settings);
            acqFun = @(x) targetCost(x, models, input_defs, AL_settings) ...
                - explorationBonus .* explorationScore(x, models, input_defs, X_existing_N, antiClusterScale, AL_settings);

        otherwise
            error('Unknown active-learning strategy: %s', AL_settings.current_strategy);
    end

    next_x = ga(acqFun, nVars, [], [], [], [], lb, ub, [], options);

    [score, rawUnc, penalty, dNearest] = explorationScore(next_x, models, input_defs, X_existing_N, antiClusterScale, AL_settings);
    [tCost, tScore, pScore, tViolation, tGate] = targetCost(next_x, models, input_defs, AL_settings);

    info = struct();
    info.strategy = AL_settings.current_strategy;

    % Exploration diagnostics at the selected point.
    info.exploreScore = score;
    info.rawUncertaintyScore = rawUnc;
    info.antiClusterPenalty = penalty;
    info.nearestDistanceNorm = dNearest;
    info.antiClusterScale = antiClusterScale;

    % Targeted-optimisation diagnostics at the selected point.
    info.targetCost = tCost;
    info.targetScore = tScore;
    info.penaltyScore = pScore;
    info.targetViolation = tViolation;
    info.targetGate = tGate;
end

function [score, uncertaintyScore, distancePenalty, dNearest] = explorationScore(x, models, input_defs, X_existing_N, d0, AL_settings)
    xN = actLearn_normalizeInputs(x, input_defs);

    sigmaTerms = [];

    for k = 1:numel(models)
        if ~isModelUsable(models(k))
            continue
        end

        % IMPORTANT: models are trained on normalised inputs.
        [~, sigma] = predict(models(k).gp, xN);
        scale = getModelScale(models(k));

        % Equal contribution from each output after dimensional normalisation.
        % Do not use exploreWeight here; this keeps exploration independent of
        % manually chosen output weights.
        sigmaTerms(end+1) = (sigma ./ scale).^2; %#ok<AGROW>
    end

    if isempty(sigmaTerms)
        uncertaintyScore = 0;
    else
        uncertaintyScore = sqrt(mean(sigmaTerms, 'omitnan'));
    end

    [distancePenalty, dNearest] = antiClusterPenalty(xN, X_existing_N, d0, AL_settings);
    score = uncertaintyScore .* distancePenalty;
end

function tf = isModelUsable(model)
    tf = isfield(model, 'gp') && ~isempty(model.gp);
    if tf && isfield(model, 'isTrained')
        tf = model.isTrained;
    end
end

function scale = getModelScale(model)
    scale = 1;
    if isfield(model, 'yScale') && isfinite(model.yScale) && model.yScale > 0
        scale = model.yScale;
    end
    scale = max(scale, eps);
end

function bonus = getTargetExplorationBonus(AL_settings)
    bonus = 0;
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, 'explorationBonus') ...
            && ~isempty(AL_settings.target.explorationBonus)
        bonus = AL_settings.target.explorationBonus;
    end
end

function d0 = estimateAntiClusterScale(X_existing_N, AL_settings)
    % Adaptive scale based on current sampling density in normalised space.
    % This avoids a fixed distance threshold that would become too restrictive
    % once the space fills in.

    defaults = struct();
    defaults.enabled = true;
    defaults.scaleFactor = 0.5;
    defaults.minScale = 0.02;
    defaults.maxScale = 0.25;
    defaults.fallbackScale = 0.10;

    ac = defaults;
    if isfield(AL_settings, 'explore') && isfield(AL_settings.explore, 'antiCluster')
        userAC = AL_settings.explore.antiCluster;
        fn = fieldnames(userAC);
        for k = 1:numel(fn)
            ac.(fn{k}) = userAC.(fn{k});
        end
    end

    if ~ac.enabled || size(X_existing_N,1) < 3
        d0 = ac.fallbackScale;
        return
    end

    D = squareform(pdist(X_existing_N));
    D(1:size(D,1)+1:end) = Inf;
    nnDist = min(D, [], 2);
    medNN = median(nnDist, 'omitnan');

    if ~isfinite(medNN) || medNN <= 0
        d0 = ac.fallbackScale;
    else
        d0 = ac.scaleFactor .* medNN;
    end

    d0 = max(d0, ac.minScale);
    d0 = min(d0, ac.maxScale);
end

function [penalty, dNearest] = antiClusterPenalty(xN, X_existing_N, d0, AL_settings)
    enabled = true;
    if isfield(AL_settings, 'explore') && isfield(AL_settings.explore, 'antiCluster') ...
            && isfield(AL_settings.explore.antiCluster, 'enabled')
        enabled = AL_settings.explore.antiCluster.enabled;
    end

    if ~enabled || isempty(X_existing_N)
        penalty = 1;
        dNearest = Inf;
        return
    end

    dNearest = min(vecnorm(X_existing_N - xN, 2, 2));

    if ~isfinite(d0) || d0 <= 0
        penalty = 1;
        return
    end

    penalty = 1 - exp(-(dNearest ./ d0).^2);

    % Numerical guardrails only.
    penalty = max(0, min(1, penalty));
end
