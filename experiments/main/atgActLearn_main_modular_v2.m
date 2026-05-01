%% ATG Active Learning Master Loop - modular design-space version
%#ok<*NUSED>
%#ok<*GVMIS>
%
% This version keeps the current optDB schema:
%   optDB(idx).actuation.alpha
%   optDB(idx).metrics.TI_mean
%
% It learns in the design/control space:
%   freq, alpha, relBeta, ampgrad, offsetgrad
%
% The actuation mode is inferred from the provided inputs. If ampgrad or
% offsetgrad is active/nonzero, the gradient ATG routine is used.

clear global lastSeedingTime recIdx optResults
global lastSeedingTime recIdx optResults

%% Configuration & hardware initialization
% Use the modular setup script for new runs. If you prefer, you can merge
% the AL_settings block from that file into your existing setup script.
setup_experimental_configs_modular_v2;

AL_settings = config.AL_settings;
dbPath = fullfile('C:\PIV_SANDBOX\', 'actLearnDB.mat');

input_defs  = actLearn_getActiveDefs(AL_settings.input_defs,  AL_settings.active_input_names,  'input');
output_defs = actLearn_getActiveDefs(AL_settings.output_defs, AL_settings.active_output_names, 'output');

input_keys  = {input_defs.key};
output_keys = {output_defs.key};


%% Load or initialize database
if isfile(dbPath)
    fprintf('Loading existing database for training: %s\n', dbPath);
    load(dbPath, 'optDB');

    if ~exist('optDB','var') || isempty(optDB)
        optDB = struct([]);
    end
else
    fprintf('No database found. Starting fresh.\n');
    optDB = struct([]);
end

% Important:
% recIdx is the recording/file index for the CURRENT acquisition folder.
% It must start at 1 for a fresh project/recording, even if optDB already
% contains previous training data.
nTrainingDBAtStart = numel(optDB);
recIdx = 1;
optResults = struct([]);

fprintf('Loaded %d existing DB entries for training. Current recording index starts at %d.\n', ...
    nTrainingDBAtStart, recIdx);

% Full training matrices from the database. These may be large.
X_all = actLearn_extractMatrixFromDB(optDB, input_keys);
Y_all = actLearn_extractMatrixFromDB(optDB, output_keys);
validRows = all(isfinite(X_all),2) & all(isfinite(Y_all),2);
X_all = X_all(validRows,:);
Y_all = Y_all(validRows,:);

fprintf('Training database contains %d complete rows for the selected inputs/outputs.\n', size(X_all,1));

% Current-run matrices only. These are what actLearn_plotStatus displays.
X_run = [];
Y_run = [];
history = initHistory();

if AL_settings.pauseBeforeLoop
    disp(' ')
    disp('Initialization/configuration complete.');
    disp('Type RUN to enter the active-learning loop, DB to stop after database extraction, or anything else to abort.');
    userMode = input('Continue? ', 's');
    if strcmpi(userMode, 'DB')
        disp('Stopped after database extraction.');
        return
    elseif ~strcmpi(userMode, 'RUN')
        disp('Aborted before active-learning loop.');
        return
    end
end

%% Active-learning loop
lastSeedingTime = tic;

for iter = 1:AL_settings.n_iter
    fprintf('\n--- Active Learning Iteration %d (Recording Index %d) ---\n', iter, recIdx);

    if size(X_all, 1) >= AL_settings.minSamplesForModel
        fprintf('Training %d GP models on %d samples...\n', numel(output_defs), size(X_all, 1));

        % GP sees normalised inputs
        X_model = actLearn_normalizeInputs(X_all, input_defs);

        [models, modelStats] = actLearn_trainOutputModels(X_model, Y_all, output_defs, ...
            'KernelFunction', AL_settings.gp.kernelFunction, ...
            'Standardize', true, ...
            'MinTrain', AL_settings.minSamplesForModel, ...
            'DoLOO', false);

        % GA returns physical/design-space point
        [x_next, acqInfo] = actLearn_getNextPt_GA(models, input_defs, output_defs, AL_settings, X_all);

        fprintf('Acquisition diagnostics: rawUnc=%.4g, antiCluster=%.4g, dNearest=%.4g, d0=%.4g, exploreScore=%.4g\n', ...
            acqInfo.rawUncertaintyScore, ...
            acqInfo.antiClusterPenalty, ...
            acqInfo.nearestDistanceNorm, ...
            acqInfo.antiClusterScale, ...
            acqInfo.exploreScore);

        params_next = vectorToParams(x_next, AL_settings.input_defs, input_defs);
    else
        fprintf('Bootstrapping: random sampling in active design space...\n');
        models = [];
        x_next = randomVector(input_defs);
        params_next = vectorToParams(x_next, AL_settings.input_defs, input_defs);
        acqInfo = struct('exploreScore', NaN, 'targetCost', NaN, 'strategy', AL_settings.current_strategy);
    end

    useGrad = inferGradientActuation(params_next, AL_settings.active_input_names);
    fprintf('Running experiment: freq=%.3g, alpha=%.3g, relBeta=%.3g, ampgrad=%.3g, offsetgrad=%.3g, mode=%s\n', ...
        params_next.freq, params_next.alpha, params_next.relBeta, params_next.ampgrad, params_next.offsetgrad, modeLabel(useGrad));

    J = atgOpt_objFcn_modular(params_next, config, hw); %#ok<NASGU>

    % Pull the record that was just appended by the objective function.
    res = optResults(recIdx-1);

    new_X = recordToRow(res, input_defs);
    new_Y = recordToRow(res, output_defs);

    X_all = [X_all; new_X]; %#ok<AGROW>
    Y_all = [Y_all; new_Y]; %#ok<AGROW>
    X_run = [X_run; new_X]; %#ok<AGROW>
    Y_run = [Y_run; new_Y]; %#ok<AGROW>

    measuredScore = measuredTargetScore(new_Y, output_defs, models);
    history.iter(end+1,1) = iter;
    history.globalIdx(end+1,1) = recIdx-1;
    history.exploreScore(end+1,1) = acqInfo.exploreScore;
    history.targetCostPred(end+1,1) = acqInfo.targetCost;
    history.targetCostMeasured(end+1,1) = measuredScore;

    % Append full result to local DB and save at every iteration.
    if isempty(optDB)
        optDB = res;
    else
        optDB(end+1) = res; %#ok<SAGROW>
    end
    save(dbPath, 'optDB');

    % Visual feedback for the current run only.
    actLearn_plotStatus(X_run, Y_run, history, input_defs, output_defs, AL_settings, iter);
end

%% Disarm system, cleanup, save data
bnc_disarm(hw.bnc)

delete(hw.bnc)
% laserDashboard is created by setup_experimental_configs_modular_v2 and may
% exist in the caller workspace depending on MATLAB script scoping.
if exist('laserDashboard','var')
    delete(laserDashboard)
end
delete(hw.laserControl)

save(fullfile(config.root_dir, "workspaceOptimization.mat"))
disp("Saved workspace matfile.")

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
diary off;


%% Local helpers ----------------------------------------------------------
function row = recordToRow(record, defs)
    row = NaN(1, numel(defs));
    for k = 1:numel(defs)
        row(k) = getByPath(record, defs(k).key);
    end
end

function val = getByPath(S, key)
    val = NaN;
    parts = strsplit(key, '.');
    tmp = S;
    for p = 1:numel(parts)
        if isstruct(tmp) && isfield(tmp, parts{p})
            tmp = tmp.(parts{p});
        else
            return
        end
    end
    if isnumeric(tmp) && isscalar(tmp)
        val = tmp;
    elseif islogical(tmp) && isscalar(tmp)
        val = double(tmp);
    end
end

function x = randomVector(input_defs)
    x = NaN(1, numel(input_defs));
    for k = 1:numel(input_defs)
        bounds = input_defs(k).range;
        x(k) = bounds(1) + rand() * (bounds(2) - bounds(1));
    end
end

function params = vectorToParams(x, all_input_defs, active_input_defs)
    params = struct();
    for k = 1:numel(all_input_defs)
        params.(all_input_defs(k).name) = all_input_defs(k).default;
    end
    for k = 1:numel(active_input_defs)
        params.(active_input_defs(k).name) = x(k);
    end
end

function useGrad = inferGradientActuation(params, active_input_names)
    gradActive = any(strcmp(active_input_names, 'ampgrad')) || any(strcmp(active_input_names, 'offsetgrad'));
    gradNonzero = false;
    if isfield(params, 'ampgrad')
        gradNonzero = gradNonzero || abs(params.ampgrad) > eps;
    end
    if isfield(params, 'offsetgrad')
        gradNonzero = gradNonzero || abs(params.offsetgrad) > eps;
    end
    useGrad = gradActive || gradNonzero;
end

function txt = modeLabel(useGrad)
    if useGrad
        txt = 'gradient';
    else
        txt = 'synchronous';
    end
end

function score = measuredTargetScore(yRow, output_defs, models)
    score = NaN;
    if isempty(yRow) || all(~isfinite(yRow))
        return
    end

    terms = [];
    for m = 1:numel(output_defs)
        if strcmpi(output_defs(m).role, 'diagnostic') || ~isfinite(yRow(m))
            continue
        end

        yScale = findModelScale(models, output_defs(m).name, yRow(m));
        err = (yRow(m) - output_defs(m).target) ./ max(yScale, eps);
        terms(end+1) = output_defs(m).targetWeight .* err.^2; %#ok<AGROW>
    end

    if ~isempty(terms)
        score = sum(terms);
    end
end

function yScale = findModelScale(models, name, yVal)
    yScale = max(abs(yVal), 1);
    for k = 1:numel(models)
        if strcmp(models(k).name, name)
            yScale = models(k).yScale;
            return
        end
    end
end

function history = initHistory()
    history = struct();
    history.iter = [];
    history.globalIdx = [];
    history.exploreScore = [];
    history.targetCostPred = [];
    history.targetCostMeasured = [];
end
