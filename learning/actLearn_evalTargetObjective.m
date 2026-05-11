function [cost, targetScore, penaltyScore, targetViolation, targetGate, detail] = ...
    actLearn_evalTargetObjective(metricValues, metricMeta, AL_settings)
%% Canonical target/penalty objective evaluator.
%
% This function contains the shared scoring logic for target optimisation.
% Use it for BOTH:
%   1) GP-predicted metric values, and
%   2) measured experimental metric values.
%
% Inputs
%   metricValues : numeric row/vector of metric values. The order must match
%                  metricMeta.
%   metricMeta   : struct array with at least .name. Optional fields:
%                  .role, .target, .yScale.
%                  role='target'  -> included in targetScore.
%                  role='penalty' -> included in penaltyScore.
%                  role='diagnostic' or missing -> ignored.
%   AL_settings  : active-learning settings with optional fields:
%                  AL_settings.targets.<metricName>
%                  AL_settings.target.tol.<metricName>
%                  AL_settings.target.relTol
%                  AL_settings.target.outsidePenalty
%                  AL_settings.target.gateSharpness
%                  AL_settings.target.penaltyScale.<metricName>
%
% Outputs
%   targetScore:
%       RMS target error normalised by user-defined tolerances.
%       targetScore ~= 1 means the candidate is roughly at the tolerance
%       boundary in the RMS sense.
%
%   targetViolation:
%       RMS of only the target error outside the tolerance band. This is zero
%       when all target terms are within tolerance.
%
%   penaltyScore:
%       RMS lower-is-better score for role='penalty' outputs, normalised by
%       model scale or optional physical penalty scales.
%
%   targetGate:
%       Smooth switch that lets penalty terms matter mostly after the target
%       region is approached.
%
%   cost:
%       Scalar objective minimised in target optimisation:
%       targetScore^2 + outsidePenalty*targetViolation^2
%       + targetGate*penaltyScore^2

    if nargin < 3
        AL_settings = struct();
    end

    metricValues = metricValues(:).';

    if isempty(metricMeta)
        targetScore = 0;
        targetViolation = 0;
        penaltyScore = 0;
        targetGate = 0;
        cost = 0;
        detail = initialiseDetailStruct();
        detail.cost = cost;
        return
    end

    if numel(metricValues) ~= numel(metricMeta)
        error('actLearn_evalTargetObjective:SizeMismatch', ...
            'metricValues must have one value per metricMeta entry.');
    end

    targetTerms = [];
    violationTerms = [];
    penaltyTerms = [];

    detail = initialiseDetailStruct();

    for k = 1:numel(metricMeta)
        y = metricValues(k);
        if ~isfinite(y)
            continue
        end

        name = getMetaField(metricMeta(k), 'name', '');
        role = getMetaField(metricMeta(k), 'role', 'diagnostic');

        if isempty(name) || strcmpi(role, 'diagnostic')
            continue
        end

        switch lower(role)
            case 'target'
                target = getTargetValue(metricMeta(k), AL_settings);
                tol = getTargetTolerance(metricMeta(k), target, AL_settings);

                e = (y - target) ./ max(tol, eps);

                targetTerms(end+1) = e.^2; %#ok<AGROW>
                violationTerms(end+1) = max(abs(e) - 1, 0).^2; %#ok<AGROW>

                detail.targetNames{end+1} = name; %#ok<AGROW>
                detail.targetMu(end+1) = y; %#ok<AGROW>
                detail.targetValue(end+1) = target; %#ok<AGROW>
                detail.targetTol(end+1) = tol; %#ok<AGROW>
                detail.targetErrNorm(end+1) = e; %#ok<AGROW>

            case 'penalty'
                scale = getPenaltyScale(metricMeta(k), AL_settings);

                % Penalty metrics are lower-is-better and usually positive.
                % If the GP predicts a slightly negative value, do not reward it.
                p = max(y, 0) ./ max(scale, eps);

                penaltyTerms(end+1) = p.^2; %#ok<AGROW>

                detail.penaltyNames{end+1} = name; %#ok<AGROW>
                detail.penaltyMu(end+1) = y; %#ok<AGROW>
                detail.penaltyScale(end+1) = scale; %#ok<AGROW>
                detail.penaltyNorm(end+1) = p; %#ok<AGROW>

            otherwise
                % Unknown roles are ignored rather than treated as penalties.
                continue
        end
    end

    targetScore = rmsFromSquaredTerms(targetTerms);
    targetViolation = rmsFromSquaredTerms(violationTerms);
    penaltyScore = rmsFromSquaredTerms(penaltyTerms);

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

function detail = initialiseDetailStruct()
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
    detail.targetScore = NaN;
    detail.targetViolation = NaN;
    detail.penaltyScore = NaN;
    detail.targetGate = NaN;
    detail.cost = NaN;
end

function val = rmsFromSquaredTerms(terms)
    if isempty(terms)
        val = 0;
    else
        val = sqrt(mean(terms, 'omitnan'));
    end
end

function value = getMetaField(meta, fieldName, defaultValue)
    if isfield(meta, fieldName) && ~isempty(meta.(fieldName))
        value = meta.(fieldName);
    else
        value = defaultValue;
    end
end

function target = getTargetValue(meta, AL_settings)
    target = getMetaField(meta, 'target', 0);
    name = getMetaField(meta, 'name', '');

    % Allow grouped target settings to override output_defs/model targets.
    if isfield(AL_settings, 'targets') && isstruct(AL_settings.targets)
        if isfield(AL_settings.targets, name)
            target = AL_settings.targets.(name);
        elseif strcmp(name, 'TI_mean') && isfield(AL_settings.targets, 'TI')
            target = AL_settings.targets.TI;
        end
    end
end

function tol = getTargetTolerance(meta, target, AL_settings)
    name = getMetaField(meta, 'name', '');

    % Explicit per-metric tolerance wins.
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, 'tol') ...
            && isstruct(AL_settings.target.tol) ...
            && isfield(AL_settings.target.tol, name)
        tol = AL_settings.target.tol.(name);
        tol = max(tol, eps);
        return
    end

    % Fallback relative tolerance for nonzero targets.
    relTol = getTargetSetting(AL_settings, 'relTol', 0.05);
    if abs(target) > eps
        tol = relTol .* abs(target);
    else
        % Zero target requires an absolute tolerance. If the user did not
        % provide one, use a small fraction of the output scale.
        tol = 0.05 .* getMetricScale(meta);
    end

    tol = max(tol, eps);
end

function scale = getPenaltyScale(meta, AL_settings)
    name = getMetaField(meta, 'name', '');

    % Optional explicit physical scale for penalty metrics.
    if isfield(AL_settings, 'target') && isfield(AL_settings.target, 'penaltyScale') ...
            && isstruct(AL_settings.target.penaltyScale) ...
            && isfield(AL_settings.target.penaltyScale, name)
        scale = AL_settings.target.penaltyScale.(name);
        if isfinite(scale) && scale > 0
            return
        end
    end

    % Default: use training-data output scale from the metric/model meta.
    scale = getMetricScale(meta);
end

function scale = getMetricScale(meta)
    scale = 1;
    if isfield(meta, 'yScale') && isfinite(meta.yScale) && meta.yScale > 0
        scale = meta.yScale;
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
