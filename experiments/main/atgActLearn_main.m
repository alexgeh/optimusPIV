%% ATG Active Learning Master Loop - Direct Extraction
%#ok<*NUSED>
%#ok<*GVMIS>
%#ok<*UNRCH>

clear global lastSeedingTime recIdx optResults
global lastSeedingTime recIdx optResults 

% --- Configuration & Initialization ---
setup_experimental_configs; % Load your existing config struct (hw, OPT_settings, etc.)
dbPath = fullfile('C:\PIV_SANDBOX\', 'optDB.mat');

% Define AL strategy
current_strategy = 'explore'; % 'explore' or 'target'
n_iter = 50;

% Optimization Targets
targets.TI = config.EVAL_settings.targetTI; % e.g., 0.125

% input_keys  = {'actuation.ampl', 'actuation.offset'}; 
input_keys  = {'actuation.alpha', 'actuation.relBeta'}; 
output_keys = {'metrics.TI_mean', 'metrics.CV_U', 'metrics.CV_TI', 'metrics.aniso_mean'};
out_names   = {'TI', 'CV_U', 'CV_TI', 'Anisotropy'}; % names for plots

% 1. Load or Initialize the Database
if isfile(dbPath)
    fprintf('Loading existing database: %s\n', dbPath);
    load(dbPath, 'optDB');

    % Pre-populate X and Y from existing records
    % Extract data from DB
    X_struct = DB_extractData(optDB, input_keys);
    Y_struct = DB_extractData(optDB, output_keys);

    % Extract into matrices (DB_extractData converts '.' to '_')
    X = [X_struct.actuation_alpha, X_struct.actuation_relBeta];
    Y = [Y_struct.metrics_TI_mean, Y_struct.metrics_CV_U, ...
        Y_struct.metrics_CV_TI, Y_struct.metrics_aniso_mean];
else
    fprintf('No database found. Starting fresh.\n');
    optDB = []; 
    X = []; Y = [];
    recIdx = 1;
end

return


%% --- Big Active Learning Loop ---
lastSeedingTime = tic;

for iter = 1:n_iter
    fprintf('\n--- Active Learning Iteration %d (Global Index %d) ---\n', iter, recIdx);
    
    %% 2. Retrain GP Models
    % We need a minimum amount of data to build the models
    if size(X, 1) >= 6
        fprintf('Training 4 GP models on %d samples...\n', size(X, 1));
        models = cell(1, 4);
        for m = 1:4
            % Standardize=true is vital as Ampl (0-100) and TI (0-0.2) have different scales
            models{m} = fitrgp(X, Y(:,m), 'KernelFunction', 'matern52', 'Standardize', true);
        end
        
        % 3. Find next measurement point via GA
        % Note: GA searches in alpha/relBeta space, GP models work in Amp/Offset space
        next_coords = actLearn_getNextPt_GA(models, config, current_strategy, targets);
        alpha_next = next_coords(1);
        relBeta_next = next_coords(2);
    else
        % Bootstrapping: Choose a random point to start filling the space
        fprintf('Bootstrapping: Random sampling...\n');
        alpha_next = rand_range(config.OPT_settings.alphaRange);
        relBeta_next = rand_range(config.OPT_settings.relBetaRange);
    end

    %% 4. Execute Physical Experiment
    % This triggers hardware and populates the optResults(recIdx) struct
    fprintf('Running Experiment: Alpha=%.2f, relBeta=%.2f\n', alpha_next, relBeta_next);
    J = atgOpt_objFcn_synchr(10, alpha_next, relBeta_next, config, hw);
    
    %% 5. Direct Data Extraction (The Memory Update)
    % We pull directly from the global struct populated by the objective function
    res = optResults(recIdx-1);
    
    % X: Actuation inputs (The GP should learn from physical Amp/Offset)
    new_X = [res.ampl, res.offset];
    
    % Y: Flow metrics
    new_Y = [res.metrics.TI_mean, ...
             res.metrics.CV_U, ...
             res.metrics.CV_TI, ...
             res.metrics.aniso_mean];
         
    % Update local matrices for the next iteration
    X = [X; new_X]; 
    Y = [Y; new_Y];

    %% 6. Persistence & Monitoring
    % Append the full result to our local database struct
    % if isempty(optDB)
    %     optDB = res;
    % else
    %     optDB(recIdx) = res; 
    % end
    % 
    % % Save to disk at every iteration so no data is lost on crash
    % save(dbPath, 'optDB');
    
    % Visual feedback for verification
    actLearn_plotStatus(X, Y, targets, iter);
    
    % Increment global record index
    % recIdx = recIdx + 1;
end


%% Disarm system, cleanup, save data
bnc_disarm(hw.bnc)

delete(hw.bnc)
delete(laserDashboard)
delete(hw.laserControl)

% Safe data
save(fullfile(config.root_dir, "workspaceOptimization.mat"))
disp("Saved workspace matfile.")

disp("!!! SHUT DOWN LASER AND CAMERAS !!!")
diary off; % Stop command line logging
