function J = atgOpt_objFcn_modular(params, config, hw)
%% Modular objective function for ATG active learning.
%
% params must use the design/control-space variables:
%   params.freq
%   params.alpha
%   params.relBeta
%   params.ampgrad
%   params.offsetgrad
%
% The actuation mode is inferred automatically:
%   ampgrad/offsetgrad active or nonzero -> gradient actuation
%   otherwise                           -> synchronous actuation

% Mutable states required for loop continuity
global lastSeedingTime
global recIdx
global optResults

AL_settings = config.AL_settings;
params = completeParams(params, AL_settings.input_defs);

plotting = config.OPT_settings.plotting; %#ok<NASGU>
theta_min = config.OPT_settings.theta_min;

elapsedTime = toc(lastSeedingTime) / 60;
if elapsedTime > config.OPT_settings.seedInterval_min
    disp("next seeding interval starting in 5sec")
    pause(5)
    openSolenoidValve(hw.valveArduino);
    pause(30) % seeding time
    closeSolenoidValve(hw.valveArduino);
    lastSeedingTime = tic;
    pause(30) % circulation of particles
    disp("seeding complete, continuing with experiments")
end

%% Build derived actuation values
actuation = buildActuation(params, theta_min, AL_settings.active_input_names);

%% Arm the system
bnc_arm(hw.bnc);
pause(0.5)

%% Ramp up laser
targetHeads = 'both';
targetAmps  = 'max';

hw.laserControl.openShutter(targetHeads);
hw.laserControl.turnOnDiode(targetHeads);
hw.laserControl.setCurrent(targetAmps, targetHeads);

%% Run ATG + PIV trigger
if actuation.useGradActuation
    disp("ATG Run - gradient mode: freq=" + num2str(actuation.freq) + ...
        "; ampl=" + num2str(actuation.ampl) + ...
        "; offset=" + num2str(actuation.offset) + ...
        "; ampgrad=" + num2str(actuation.ampgrad) + ...
        "; offsetgrad=" + num2str(actuation.offsetgrad))
else
    disp("ATG Run - synchronous mode: freq=" + num2str(actuation.freq) + ...
        "; ampl=" + num2str(actuation.ampl) + ...
        "; offset=" + num2str(actuation.offset))
end

runAtg_modular(actuation, config, hw);

hw.laserControl.shutdown(targetHeads)
pause(0.5)

%% Transfer raw PIV to processing directory
waitForDownloadCycle(config.log_path, 60);
transfer_files(config.raw_PIV_dir, config.davis_templ_mraw, recIdx, "mraw");
pause(1)

%% Process PIV
processPIV(config.davis_exe, config.davis_lvs_file, config.davis_set_file);

%% Transfer processed PIV data to storage directory
transfer_files(config.davis_templ_dir, config.proc_PIV_dir, recIdx, "vc7");

%% Analyze PIV
PIVfolder = fullfile(config.proc_PIV_dir, sprintf('ms%04d', recIdx));
[J, J_comp, metrics, fields] = objEval_turbulenceIntensity(PIVfolder, config.EVAL_settings);

metrics = ensureLoggedMetrics(metrics, AL_settings.output_defs);

printObjectiveStatus(J, J_comp, actuation);

%% Build and save result record
record = buildRecord(recIdx, J, J_comp, metrics, fields, actuation, config, AL_settings);
if isempty(optResults) || ~isstruct(optResults)
    optResults = repmat(record, 0, 1);
end
optResults(recIdx) = record;

stepData = record;
stepFileName = fullfile(config.analysis_PIV_dir, sprintf('optStep_ms%04d.mat', recIdx));
save(stepFileName, 'stepData');
disp("Saved step data to: " + stepFileName);

recIdx = recIdx + 1;
end


%% Local helpers ----------------------------------------------------------
function params = completeParams(params, input_defs)
    for k = 1:numel(input_defs)
        name = input_defs(k).name;
        if ~isfield(params, name) || isempty(params.(name)) || ~isfinite(params.(name))
            params.(name) = input_defs(k).default;
        end
    end
end

function actuation = buildActuation(params, theta_min, active_input_names)
    beta = params.alpha * params.relBeta; % Ensures always alpha >= beta
    offset = -(90 - params.alpha - theta_min);
    ampl = 180 - 2*theta_min - params.alpha - beta;

    useGrad = any(strcmp(active_input_names, 'ampgrad')) || ...
              any(strcmp(active_input_names, 'offsetgrad')) || ...
              abs(params.ampgrad) > eps || abs(params.offsetgrad) > eps;

    actuation = struct();
    actuation.freq = params.freq;
    actuation.alpha = params.alpha;
    actuation.relBeta = params.relBeta;
    actuation.beta = beta;
    actuation.ampl = ampl;
    actuation.offset = offset;
    actuation.ampgrad = params.ampgrad;
    actuation.offsetgrad = params.offsetgrad;
    actuation.useGradActuation = useGrad;
end

function metrics = ensureLoggedMetrics(metrics, output_defs)
    for k = 1:numel(output_defs)
        name = output_defs(k).name;
        if ~isfield(metrics, name)
            metrics.(name) = NaN;
        end
    end
end

function record = buildRecord(idx, J, J_comp, metrics, fields, actuation, config, AL_settings)
    record = struct();
    record.caseID = string(getCaseID(config, idx));
    record.description = string(describeRun(actuation));
    record.weights = getWeights(AL_settings.output_defs);
    record.iteration = idx;
    record.J = J;
    record.actuation = actuation;
    record.J_comp = J_comp;
    record.metrics = metrics;
    record.fieldsRef = '';
    record.rawDataRef = '';
    record.optSettings = config.OPT_settings;
    record.optSettings.AL_settings = AL_settings;
    record.caseDir = config.root_dir;
    record.meta = struct();
    record.meta.timestamp = datetime('now');
    record.meta.useGradActuation = actuation.useGradActuation;
    record.meta.active_input_names = AL_settings.active_input_names;
    record.meta.active_output_names = AL_settings.active_output_names;
    record.fields = fields;
end

function caseID = getCaseID(config, idx)
    [~, baseName] = fileparts(char(config.root_dir));
    if isempty(baseName)
        caseID = sprintf('ATG_activeLearning_%04d', idx);
    else
        caseID = sprintf('%s_%04d', baseName, idx);
    end
end

function txt = describeRun(actuation)
    if actuation.useGradActuation
        txt = 'gradient actuation active-learning run';
    else
        txt = 'synchronous actuation active-learning run';
    end
end

function weights = getWeights(output_defs)
    weights = struct();
    for k = 1:numel(output_defs)
        weights.(output_defs(k).name) = output_defs(k).targetWeight;
    end
end

function printObjectiveStatus(J, J_comp, actuation)
    msg = "Current: J = " + num2str(J);

    compNames = fieldnames(J_comp);
    for k = 1:numel(compNames)
        val = J_comp.(compNames{k});
        if isnumeric(val) && isscalar(val)
            msg = msg + ", " + compNames{k} + " = " + num2str(val);
        end
    end

    msg = msg + ", alpha = " + num2str(actuation.alpha) + ...
        ", relBeta = " + num2str(actuation.relBeta) + ...
        ", freq = " + num2str(actuation.freq) + ...
        ", ampl = " + num2str(actuation.ampl) + ...
        ", offset = " + num2str(actuation.offset) + ...
        ", ampgrad = " + num2str(actuation.ampgrad) + ...
        ", offsetgrad = " + num2str(actuation.offsetgrad);

    disp(msg)
end
