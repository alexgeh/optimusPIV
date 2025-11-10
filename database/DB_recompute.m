function optDB = DB_recompute(optDB, filter, opts)
% DB_recompute  Recompute metrics and fields from raw PIV data and update optDB.
%
%   optDB = DB_recompute(optDB)
%   optDB = DB_recompute(optDB, filter)
%   optDB = DB_recompute(optDB, filter, opts)
%
% Inputs:
%   optDB  - main DB struct array
%   filter - optional: caseID string, or function handle to pass to DB_filterCases,
%            or empty to select all entries
%   opts   - optional struct with fields:
%            .force      (logical) : overwrite existing metrics (default false)
%            .saveFields (logical) : save recomputed fields into DB (default false)
%            .verbose    (logical) : print progress (default true)
%
% Behavior:
%   Each element of optDB is one iteration. This function recomputes each selected
%   iteration's metrics/fields and writes back to the matching entry in optDB by
%   matching both caseDir and iteration.

    if nargin < 2 || isempty(filter)
        subset = optDB;
    else
        % support calling with a caseID string or function handle or direct subset
        if ischar(filter) || isstring(filter)
            subset = DB_filterCases(optDB, 'caseID', char(filter));
        elseif isa(filter, 'function_handle')
            subset = DB_filterCases(optDB, filter);
        elseif isstruct(filter)
            % assume already a subset
            subset = filter;
        else
            error('Unsupported filter type.');
        end
    end

    if nargin < 3, opts = struct(); end
    if ~isfield(opts,'force'), opts.force = false; end
    if ~isfield(opts,'saveFields'), opts.saveFields = false; end
    if ~isfield(opts,'verbose'), opts.verbose = true; end

    if isempty(subset)
        if opts.verbose, fprintf('DB_recompute: no matching entries to recompute.\n'); end
        return;
    end

    % Precompute lookup arrays for fast matching
    allCaseDirs = string({optDB.caseDir});
    allIters    = [optDB.iteration];

    % For reporting
    nUpdated = 0;
    nMissing = 0;

    % Loop through each selected (subset) entry and recompute + merge back
    for sIdx = 1:numel(subset)
        s = subset(sIdx);

        % Determine caseDir and iteration for this subset entry
        caseDir = s.caseDir;
        iterIdx = s.iteration;

        if opts.verbose
            fprintf('Recomputing: case="%s" iter=%d ... ', caseDir, iterIdx);
        end

        % Build PIV folder path: assume msXXXX numbering matches iteration (existing logic)
        % If you want a different mapping, change this.
        PIVfolder = fullfile(caseDir, 'proc_PIV', sprintf('ms%.4d', iterIdx));
        if ~isfolder(PIVfolder)
            warning('DB_recompute:MissingPIV', 'PIV folder not found: %s', PIVfolder);
            nMissing = nMissing + 1;
            if opts.verbose, fprintf('MISSING PIV folder\n'); end
            continue;
        end

        % Load PIV data (user-supplied loadpiv)
        try
            D = loadpiv(PIVfolder);
        catch ex
            warning('DB_recompute:LoadPIV', 'Error loading PIV data from %s: %s', PIVfolder, ex.message);
            nMissing = nMissing + 1;
            if opts.verbose, fprintf('FAILED to load PIV\n'); end
            continue;
        end

        x = D.x; y = D.y; u = D.u; v = D.v;
        % sanitize NaNs
        u(isnan(u)) = 0;
        v(isnan(v)) = 0;

        % Resolve meta: support either nested .meta or flattened keys at top-level
        if isfield(s, 'meta') && isstruct(s.meta) && ~isempty(s.meta)
            m = s.meta;
        else
            % fallback: treat s itself as meta (flattened)
            m = s;
        end

        % Provide safe defaults
        if ~isfield(m, 'xCropRange') || isempty(m.xCropRange)
            m.xCropRange = [min(x(:)), max(x(:))];
        end
        if ~isfield(m, 'yCropRange') || isempty(m.yCropRange)
            m.yCropRange = [min(y(:)), max(y(:))];
        end
        if ~isfield(m, 'nProcFrames') || isempty(m.nProcFrames)
            m.nProcFrames = size(u,3);
        end

        % Crop fields (user-supplied cropFields)
        try
            [x_crop,y_crop,u_crop,v_crop] = cropFields(m.xCropRange, m.yCropRange, x, y, u, v);
        catch ex
            warning('DB_recompute:CropFailed', 'cropFields failed for %s iter %d: %s', caseDir, iterIdx, ex.message);
            nMissing = nMissing + 1;
            if opts.verbose, fprintf('CROP FAILED\n'); end
            continue;
        end

        % Trim to requested number of frames
        nFrames = min(m.nProcFrames, size(u_crop,3));
        u_crop = u_crop(:,:,1:nFrames);
        v_crop = v_crop(:,:,1:nFrames);

        % Compute metrics & fields (using user function turbulenceMetrics)
        try
            [metrics, fields] = turbulenceMetrics(u_crop, v_crop, x_crop, y_crop, false);
        catch ex
            warning('DB_recompute:MetricsFailed', 'turbulenceMetrics failed for %s iter %d: %s', caseDir, iterIdx, ex.message);
            nMissing = nMissing + 1;
            if opts.verbose, fprintf('METRICS FAILED\n'); end
            continue;
        end

        % Now merge back into optDB by matching both caseDir AND iteration
        matchMask = (allCaseDirs == string(caseDir)) & (allIters == iterIdx);
        matchIdx = find(matchMask, 1);
        if isempty(matchIdx)
            warning('DB_recompute:NoMatch', 'No matching entry found in optDB for case="%s" iter=%d', caseDir, iterIdx);
            nMissing = nMissing + 1;
            if opts.verbose, fprintf('NO MATCH\n'); end
            continue;
        end

        % Update metrics (respect opts.force: if not force and metrics exist, merge only missing fields)
        if ~opts.force && isfield(optDB(matchIdx), 'metrics') && ~isempty(optDB(matchIdx).metrics)
            % merge fields: overwrite existing fields only when new values are non-NaN
            newNames = fieldnames(metrics);
            for fn = newNames'
                fname = fn{1};
                try
                    val = metrics.(fname);
                    if ~isempty(val) && ~(isnumeric(val) && all(isnan(val)))
                        optDB(matchIdx).metrics.(fname) = val;
                    end
                catch
                    % ignore
                end
            end
        else
            optDB(matchIdx).metrics = metrics;
        end

        % Save fields if requested (overwrite or set)
        if opts.saveFields
            optDB(matchIdx).fields = fields;
        end

        if opts.verbose, fprintf('OK\n'); end
        nUpdated = nUpdated + 1;
    end

    if opts.verbose
        fprintf('DB_recompute: updated %d entries, %d failures.\n', nUpdated, nMissing);
    end
end
