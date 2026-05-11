function [cost, targetScore, penaltyScore, targetViolation, targetGate, detail] = targetCost(x, models, input_defs, AL_settings)
%% Predict the soft feasibility-first target objective from GP models.
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
%
% The actual scoring is delegated to actLearn_evalTargetObjective.m so that
% predicted and measured diagnostics use exactly the same formula.

    xN = actLearn_normalizeInputs(x, input_defs);

    muValues = NaN(1, numel(models));

    for k = 1:numel(models)
        if ~isModelUsable(models(k))
            continue
        end

        role = getModelField(models(k), 'role', 'diagnostic');
        if strcmpi(role, 'diagnostic')
            continue
        end

        % IMPORTANT: models are trained on normalised inputs.
        muValues(k) = predict(models(k).gp, xN);
    end

    [cost, targetScore, penaltyScore, targetViolation, targetGate, detail] = ...
        actLearn_evalTargetObjective(muValues, models, AL_settings);

    detail.xPhysical = x;
    detail.xNormalised = xN;
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
