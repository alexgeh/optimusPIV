function optDB = DB_addCase(optDB, caseDir, meta)
% DB_addCase Add all optimization iterations from one case folder to the database
%   optDB = DB_addCase(optDB, caseDir, meta)
%
% Inputs:
%   optDB   - existing DB (struct array) or []
%   caseDir - folder containing workspaceOptimization.mat
%   meta    - struct with fields such as:
%               caseID, description, weights, xCropRange, yCropRange,
%               nProcFrames, TI_target, dudy_target, etc.
%
% Notes:
%   - Each iteration becomes one entry in optDB
%   - All provided meta content is stored under entry.meta
%   - Missing metric/J_comp fields across cases are auto-filled

    %% --- Validate inputs and load case data ---
    if nargin < 3, meta = struct(); end
    if ~isfolder(caseDir)
        error('DB_addCase:BadFolder', 'caseDir does not exist: %s', caseDir);
    end

    wsFile = fullfile(caseDir, 'workspaceOptimization.mat');
    if ~isfile(wsFile)
        error('DB_addCase:MissingFile', 'workspaceOptimization.mat not found in %s', caseDir);
    end
    S = load(wsFile);
    if ~isfield(S, 'optResults')
        error('DB_addCase:MissingVar', 'optResults not found in %s', wsFile);
    end
    optResults = S.optResults;
    nIter = numel(optResults);
    if nIter == 0
        warning('DB_addCase:Empty', 'optResults is empty in %s', caseDir);
        return;
    end

    %% --- Gather union of actuation/metric/J_comp fields (from case and existing DB) ---
    % actuation-like top-level fields in optResults (exclude J, J_comp, metrics, fields)
    actFields = fieldnames(optResults(1));
    actFields = setdiff(actFields, {'J','J_comp','metrics','fields'});

    % metric fields found in this case (if any)
    metFields = {};
    if isfield(optResults(1), 'metrics') && isstruct(optResults(1).metrics)
        metFields = fieldnames(optResults(1).metrics);
    end

    % J_comp fields found in this case (if any)
    JcFields = {};
    if isfield(optResults(1), 'J_comp') && isstruct(optResults(1).J_comp)
        JcFields = fieldnames(optResults(1).J_comp);
    end

    % merge with existing DB fieldnames for compatibility
    if ~isempty(optDB)
        % ensure existing DB has nested substructs before union
        if isfield(optDB(1), 'actuation'), existingAct = fieldnames(optDB(1).actuation); else existingAct = {}; end
        if isfield(optDB(1), 'metrics'),   existingMet = fieldnames(optDB(1).metrics);   else existingMet = {}; end
        if isfield(optDB(1), 'J_comp'),    existingJc  = fieldnames(optDB(1).J_comp);    else existingJc  = {}; end

        actFields = union(actFields, existingAct);
        metFields = union(metFields, existingMet);
        JcFields  = union(JcFields,  existingJc);
    end

    %% --- Build entry template, including nested meta ---
    % Top-level convenience fields kept for fast filtering
    caseID = getfieldSafe(meta, 'caseID', '');
    description = getfieldSafe(meta, 'description', '');
    weights = getfieldSafe(meta, 'weights', struct());

    entryTemplate = struct( ...
        'caseID', string(caseID), ...
        'description', string(description), ...
        'weights', weights, ...
        'iteration', [], ...
        'J', [], ...
        'actuation', struct(), ...
        'J_comp', struct(), ...
        'metrics', struct(), ...
        'fieldsRef', '', ...
        'rawDataRef', '', ...
        'optSettings', getfieldSafe(S, 'optPIV_settings', struct()), ...
        'caseDir', caseDir, ...
        'meta', meta ...                % <-- store entire meta struct here
    );

    % initialize nested actuation/metrics/J_comp with NaN fields
    for f = actFields', entryTemplate.actuation.(f{1}) = NaN; end
    for f = JcFields',  entryTemplate.J_comp.(f{1})    = NaN; end
    for f = metFields', entryTemplate.metrics.(f{1})   = NaN; end

    % Preallocate array of identical templates
    newEntries = repmat(entryTemplate, nIter, 1);

    %% --- Fill each entry from optResults ---
    for k = 1:nIter
        r = optResults(k);
        e = entryTemplate;        % copy template

        e.iteration = k;
        e.J = getfieldSafe(r, 'J', NaN);

        % Fill actuation fields (from optResults)
        for f = actFields'
            e.actuation.(f{1}) = getfieldSafe(r, f{1}, NaN);
        end

        % Fill J_comp (dynamically add extra J_comp fields if present)
        if isfield(r, 'J_comp') && isstruct(r.J_comp)
            for ff = fieldnames(r.J_comp)'
                fn = ff{1};
                if ~isfield(e.J_comp, fn)
                    % add this field to all existing templates (so structure remains consistent)
                    for p = 1:numel(newEntries)
                        newEntries(p).J_comp.(fn) = NaN;
                    end
                end
                e.J_comp.(fn) = r.J_comp.(fn);
            end
        end

        % Fill metrics (dynamically add extra metric fields if present)
        if isfield(r, 'metrics') && isstruct(r.metrics)
            for ff = fieldnames(r.metrics)'
                fn = ff{1};
                if ~isfield(e.metrics, fn)
                    for p = 1:numel(newEntries)
                        newEntries(p).metrics.(fn) = NaN;
                    end
                end
                e.metrics.(fn) = r.metrics.(fn);
            end
        end

        % Fields / raw references
        avgFieldsRef = fullfile(caseDir, 'avg_fields.mat');
        e.fieldsRef = conditionalFile(avgFieldsRef);
        rawRef = fullfile(caseDir, 'raw');
        e.rawDataRef = conditionalDir(rawRef);

        % per-iteration optSettings override (if present)
        if isfield(r, 'optSettings')
            e.optSettings = r.optSettings;
        end

        % ensure meta is present (keep original meta)
        e.meta = meta;

        newEntries(k) = e;
    end

    %% --- Harmonize and append to DB ---
    if isempty(optDB)
        optDB = newEntries;
    else
        optDB = unifyStructs(optDB, newEntries);
    end

    fprintf('Added %d iterations from %s (caseID=%s)\n', nIter, caseDir, string(caseID));
end


%% ---------------- Helper functions ----------------
function val = getfieldSafe(S, f, default)
    if nargin < 3, default = []; end
    if isempty(S) || (~isstruct(S) && ~isobject(S)), val = default; return; end
    if isfield(S, f), val = S.(f); else val = default; end
end

function p = conditionalFile(f)
    if isfile(f), p = f; else p = ''; end
end

function p = conditionalDir(d)
    if isfolder(d), p = d; else p = ''; end
end

function DB = unifyStructs(DB1, DB2)
    % Ensure both struct arrays have identical top-level fields and safe defaults
    allFields = union(fieldnames(DB1), fieldnames(DB2));

    DB1 = addMissing(DB1, allFields);
    DB2 = addMissing(DB2, allFields);

    % Concatenate
    DB = [DB1; DB2];
end

function S = addMissing(S, fieldList)
    % Add missing top-level fields. If the missing field is 'meta', set default to empty struct.
    for f = fieldList'
        fname = f{1};
        if ~isfield(S, fname)
            if strcmp(fname, 'meta')
                % assign empty struct for meta (keeps nested fields consistent)
                [S.(fname)] = deal(struct());
            else
                [S.(fname)] = deal([]); %#ok<AGROW>
            end
        end
    end
end
