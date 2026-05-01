function globalInfo = actLearn_globalUncertainty(models, AL_settings, nInputs)
%% Estimate global GP uncertainty over a fixed candidate set.
%
% The GP models are assumed to be trained on normalised inputs.
% Therefore, the candidate set is generated directly in [0,1]^d.
%
% This diagnostic is independent of the GA-selected point and should be
% used to assess overall exploration convergence.

    if nargin < 3 || isempty(nInputs)
        error('nInputs must be provided.');
    end

    % Defaults
    if ~isfield(AL_settings, 'explore')
        AL_settings.explore = struct();
    end

    if ~isfield(AL_settings.explore, 'globalUncertainty')
        AL_settings.explore.globalUncertainty = struct();
    end

    gset = AL_settings.explore.globalUncertainty;

    if ~isfield(gset, 'nCandidates') || isempty(gset.nCandidates)
        gset.nCandidates = 10000;
    end

    if ~isfield(gset, 'seed') || isempty(gset.seed)
        gset.seed = 1;
    end

    nCandidates = gset.nCandidates;

    % Use local random stream so this diagnostic does NOT affect experiment
    % randomness, GA, random bootstrapping, etc.
    s = RandStream('mt19937ar', 'Seed', gset.seed);
    XcandN = rand(s, nCandidates, nInputs);

    nModels = numel(models);
    sigmaNorm = NaN(nCandidates, nModels);

    for m = 1:nModels
        if ~isfield(models(m), 'isTrained') || ~models(m).isTrained
            continue
        end

        [~, sd] = predict(models(m).gp, XcandN);

        yScale = models(m).yScale;
        if ~isfinite(yScale) || yScale <= 0
            yScale = 1;
        end

        sigmaNorm(:,m) = sd ./ yScale;
    end

    uncScore = sqrt(mean(sigmaNorm.^2, 2, 'omitnan'));

    globalInfo = struct();
    globalInfo.meanUncertainty   = mean(uncScore, 'omitnan');
    globalInfo.medianUncertainty = median(uncScore, 'omitnan');
    globalInfo.p90Uncertainty    = prctile(uncScore, 90);
    globalInfo.p99Uncertainty    = prctile(uncScore, 99);
    globalInfo.maxUncertainty    = max(uncScore, [], 'omitnan');

    globalInfo.meanByOutput = mean(sigmaNorm, 1, 'omitnan');
    globalInfo.nCandidates = nCandidates;
    globalInfo.seed = gset.seed;
end
