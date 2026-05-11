function [diag, detail] = actLearn_evalMeasuredTargetObjective(yMeasured, output_defs, AL_settings, metricMeta)
%% Evaluate measured target diagnostics after an experiment.
%
% Use this immediately after a new experiment has produced one measured
% output row. Store diag fields in history/results/DB before plotting.
%
% Inputs
%   yMeasured   : measured output row in the same order as output_defs
%   output_defs : active output definitions
%   AL_settings : active-learning settings
%   metricMeta  : optional. Pass models here if you want measured penalty
%                 scaling to use the same yScale values as the GP models.
%
% Outputs
%   diag.targetCostMeasured
%   diag.targetScoreMeasured
%   diag.penaltyScoreMeasured
%   diag.targetViolationMeasured
%   diag.targetGateMeasured
%   detail: metric-level diagnostic details from actLearn_evalTargetObjective

    if nargin < 4 || isempty(metricMeta)
        meta = output_defs;
    else
        meta = mergeOutputMeta(output_defs, metricMeta);
    end

    [cost, targetScore, penaltyScore, targetViolation, targetGate, detail] = ...
        actLearn_evalTargetObjective(yMeasured, meta, AL_settings);

    diag = struct();
    diag.targetCostMeasured = cost;
    diag.targetScoreMeasured = targetScore;
    diag.penaltyScoreMeasured = penaltyScore;
    diag.targetViolationMeasured = targetViolation;
    diag.targetGateMeasured = targetGate;
    diag.targetDetailMeasured = detail;
end

function meta = mergeOutputMeta(output_defs, metricMeta)
%% Copy role/target/yScale metadata from metricMeta by matching .name.
%
% output_defs defines the ordering of yMeasured. metricMeta, usually models,
% may contain useful yScale values and/or role settings. Existing fields in
% output_defs are preserved unless they are empty.

    meta = output_defs;

    if isempty(output_defs) || isempty(metricMeta) || ...
            ~isfield(output_defs, 'name') || ~isfield(metricMeta, 'name')
        return
    end

    metaNames = {metricMeta.name};
    fieldsToCopy = {'role', 'target', 'yScale'};

    for i = 1:numel(meta)
        name = meta(i).name;
        j = find(strcmp(metaNames, name), 1, 'first');
        if isempty(j)
            continue
        end

        for f = 1:numel(fieldsToCopy)
            fieldName = fieldsToCopy{f};

            hasExisting = isfield(meta, fieldName) && ~isempty(meta(i).(fieldName));
            hasSource = isfield(metricMeta, fieldName) && ~isempty(metricMeta(j).(fieldName));

            if ~hasExisting && hasSource
                meta(i).(fieldName) = metricMeta(j).(fieldName);
            end
        end
    end
end
