function [cost, targetScore, penaltyScore, targetViolation, targetGate, detail] = targetCost(x, models, input_defs, AL_settings)
%% Soft feasibility-first target objective for active-learning optimisation.
%
% Inputs
%   x           : candidate in PHYSICAL/DESIGN coordinates
%   models      : struct array of GP models trained on NORMALISED inputs
%   input_defs  : active input definitions used for normalising x
%   AL_settings : active-learning settings with optional fields:
%       AL_settings.targets.<metricName>
%       AL_settings.target.tol.<metricName>
%       AL_settings.target.relTol
%       AL_settings.target.outsidePenalty
%       AL_settings.target.gateSharpness
%       AL_settings.target.penaltyScale.<metricName>
%
% Output scores
%   targetScore:
%       RMS target error normalised by user-defined tolerances.
%       targetScore ~= 1 means the candidate is roughly at the tolerance
%       boundary in the RMS sense.
%
%   targetViolation:
%       RMS of only the error outside the tolerance band. This is zero if all
%       target terms are within tolerance.
%
%   penaltyScore:
%       RMS lower-is-better score for role='penalty' outputs, normalised by
%       model scale or optional physical penalty scales.
%
%   targetGate:
%       Smooth switch that lets CV/aniso penalty terms matter mostly after the
%       target region is approached.
%
%   cost:
%       targetScore^2 + outsidePenalty*targetViolation^2
%       + targetGate*penaltyScore^2

    xN = actLearn_normalizeInputs(x, input_defs);

    targetTerms = [];
    violationTerms = [];
    penaltyTerms = [];

    detail = struct();
    detail.targetNames = {};
    detail.targetMu = [];
    detail.targetValue = [];
    detail.targetTol = [];
    detail.targetErrNorm = [];
    detail.penaltyNames = {};
    detail.penaltyMu = [];
    detail.penaltyScale = [];
    detail.penaltyNorm = [];

    for k = 1:numel(models)
        if ~isModelUsable(models(k))
            continue
        end

        role = getModelField(models(k), 'role', 'diagnostic');
        if strcmpi(role, 'diagnostic')
            continue
        end

        % IMPORTANT: models are trained on normalised inputs.
        mu = predict(models(k).gp, xN);

        switch lower(role)
            case 'target'
                target = getTargetValue(models(k), AL_settings);
                tol = getTargetTolerance(models(k), target, AL_settings);

                e = (mu - target) ./ max(tol, eps);
                targetTerms(end+1) = e.^2; %#ok<AGROW>
                violationTerms(end+1) = max(abs(e) - 1, 0).^2; %#ok<AGROW>

                detail.targetNames{end+1} = models(k).name; %#ok<AGROW>
                detail.targetMu(end+1) = mu; %#ok<AGROW>
                detail.targetValue(end+1) = target; %#ok<AGROW>
                detail.targetTol(end+1) = tol; %#ok<AGROW>
                detail.targetErrNorm(end+1) = e; %#ok<AGROW>

            case 'penalty'
                scale = getPenaltyScale(models(k), AL_settings);

                % Penalty metrics are lower-is-better and usually positive.
                % If the GP predicts a slightly negative value, do not reward it.
                p = max(mu, 0) ./ max(scale, eps);
                penaltyTerms(end+1) = p.^2; %#ok<AGROW>

                detail.penaltyNames{end+1} = models(k).name; %#ok<AGROW>
                detail.penaltyMu(end+1) = mu; %#ok<AGROW>
                detail.penaltyScale(end+1) = scale; %#ok<AGROW>
                detail.penaltyNorm(end+1) = p; %#ok<AGROW>
        end
    end

    targetScore = rmsOrZero(targetTerms);
    targetViolation = rmsOrZero(violationTerms);
    penaltyScore = rmsOrZero(penaltyTerms);

    outsidePenalty = getTargetSetting(AL_settings, 'outsidePenalty', 10);
    gateSharpness  = getTargetSetting(AL_settings, 'gateSharpness', 10);

    % targetScore = 1 roughly means at the user-defined tolerance boundary.
    % For targetScore < 1, targetGate ~ 1 and penalty terms become important.
    % For targetScore > 1, targetGate decreases, so target matching dominates.
    targetGate = 1 ./ (1 + exp(gateSharpness .* (targetScore - 1)));

    cost = targetScore.^2 ...
         + outsidePenalty .* targetViolation.^2 ...
         + targetGate .* penaltyScore.^2;

    detail.targetScore = targetScore;
    detail.targetViolation = targetViolation;
    detail.penaltyScore = penaltyScore;
    detail.targetGate = targetGate;
    detail.cost = cost;
end

function val = rmsOrZero(terms)
    if isempty(terms)
        val = 0;
    else
        val = sqrt(mean(terms, 'omitnan'));
    end
end

function tf = isModelUsable(model)
    tf = isfield(model, 'gp') && ~isempty(model.gp);
    if tf && isfield(model, 'isTrained')
        tf = model.isTrained;
    end
end

function value = getModelField(model, fieldName, defaultValue)
    if isfield(model, fieldName) && ~isempty(model.(fieldName))
        value = model.(fieldName);
    else
        value = defaultValue;
    end
end

function target = getTargetValue(model, AL_settings)
    target = getModelField(model, 'target', 0);

    % Allow grouped target settings to override output_defs targets.
    if isfield(AL_settings, 'targets') && isstruct(AL_settings.targets)
        if isfield(AL_settings.targets, model.name)
            target = AL_settings.targets.(model.name);
        elseif strcmp(model.name, 'TI_mean') && isfield(AL_settings.targets, 'TI')
            target = AL_settings.targets.TI;
        end
    end
end

function tol = getTargetTolerance(model, target, AL_settings)
    % Explicit per-metric tolerance wins.
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, 'tol') ...
            && isstruct(AL_settings.target.tol) ...
            && isfield(AL_settings.target.tol, model.name)
        tol = AL_settings.target.tol.(model.name);
        return
    end

    % Fallback relative tolerance for nonzero targets.
    relTol = getTargetSetting(AL_settings, 'relTol', 0.05);
    if abs(target) > eps
        tol = relTol .* abs(target);
    else
        % Zero target requires an absolute tolerance. If the user did not
        % provide one, use a small fraction of the model output scale.
        tol = 0.05 .* getModelScale(model);
    end

    tol = max(tol, eps);
end

function scale = getPenaltyScale(model, AL_settings)
    % Optional explicit physical scale for penalty metrics.
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, 'penaltyScale') ...
            && isstruct(AL_settings.target.penaltyScale) ...
            && isfield(AL_settings.target.penaltyScale, model.name)
        scale = AL_settings.target.penaltyScale.(model.name);
        if isfinite(scale) && scale > 0
            return
        end
    end

    % Default: use training-data output scale from the model. This makes
    % CV_U, CV_TI, and anisotropy dimensionless without subjective weights.
    scale = getModelScale(model);
end

function scale = getModelScale(model)
    scale = 1;
    if isfield(model, 'yScale') && isfinite(model.yScale) && model.yScale > 0
        scale = model.yScale;
    end
    scale = max(scale, eps);
end

function value = getTargetSetting(AL_settings, fieldName, defaultValue)
    value = defaultValue;
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, fieldName) ...
            && ~isempty(AL_settings.target.(fieldName))
        value = AL_settings.target.(fieldName);
    end
end
