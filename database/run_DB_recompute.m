%% Script to recompute ATG PIV optimization DB data
%#ok<*SAGROW>
clear


%% Set up local file directories:
localPC = 1;
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\";
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2026_optimusPIV\fullOptimizations\";
end
dbFileName = fullfile(rootDataDir, 'optDB.mat');
load(dbFileName); % Load all the optimization data


%% Recompute
% 1. Setup recompute options
opts = struct();
opts.force      = true;  % Set to true to overwrite existing metrics
opts.saveFields = false; % Set to true if you want to store the large fields in the DB
opts.verbose    = true;  % Print progress
opts.relCrop    = 0.05;  % 5% relative crop margin

% 2. Extract all caseIDs into a string array for easy searching
% (Note: if your struct uses 'caseDir' instead of 'caseID' for the string, change the field name below)
all_caseIDs = string({optDB.caseID}); 

% 3. Find all entries where the caseID starts with <string>
match_mask = startsWith(all_caseIDs, "2025");

% 4. Create the subset struct array
target_subset = optDB(match_mask);

% Check if we found anything
num_found = sum(match_mask);
if num_found == 0
    fprintf('No cases found starting with "202604". Exiting.\n');
else
    fprintf('Found %d matching entries. Starting recomputation...\n', num_found);
    
    % 5. Run DB_recompute
    % Because we pass 'target_subset' (a struct), DB_recompute will automatically 
    % process only these entries and merge the results back into the main optDB.
    optDB = DB_recompute(optDB, target_subset, opts);
    
    fprintf('Recomputation complete!\n');
end
save(dbFileName, "optDB", "-append")
fprintf('Saved data base to: %s\n', dbFileName);
