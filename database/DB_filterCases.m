function subset = DB_filterCases(optDB, key, cond)
% DB_filterCases  Filter the database by a single condition (robust).
%
% subset = DB_filterCases(optDB, key, cond)
% - key : string, supports nested fields with dot notation e.g. 'metrics.TI_mean'
% - cond: either a value to match (isequal) or a function handle that returns scalar logical
%
% Examples:
%   run5 = DB_filterCases(optDB, 'caseID', '20251017_ATG_bayes_opt_3');
%   freqHigh = DB_filterCases(optDB, 'actuation.freq', @(f) f > 5);
%   runContains = DB_filterCases(optDB, 'description', @(s) contains(string(s),'isotropic'));

    if nargin < 3
        error('DB_filterCases requires (optDB, key, cond)');
    end
    if isempty(optDB)
        subset = optDB;
        return;
    end

    keyParts = strsplit(key, '.');
    n = numel(optDB);
    keep = false(n,1);

    for i = 1:n
        % safe get
        val = safeGetField(optDB(i), keyParts);

        % convenience fallback: user asked 'meta.caseID' but DB stores 'caseID' top-level
        if isempty(val) && numel(keyParts) == 2 && strcmpi(keyParts{1}, 'meta')
            alt = keyParts{2};
            if isfield(optDB(i), alt)
                val = optDB(i).(alt);
            end
        end

        % evaluate condition
        if isa(cond, 'function_handle')
            try
                r = cond(val);
                % require scalar logical / numeric -> logical
                if islogical(r) && isscalar(r)
                    keep(i) = r;
                elseif isnumeric(r) && isscalar(r)
                    keep(i) = (r ~= 0);
                else
                    % non-scalar or unsupported -> false
                    keep(i) = false;
                end
            catch
                % cond threw an error (e.g. contains([],...)) -> treat as false
                keep(i) = false;
            end
        else
            % direct equality test (works for strings, numbers, etc.)
            try
                keep(i) = isequal(val, cond);
            catch
                keep(i) = false;
            end
        end
    end

    subset = optDB(keep);
end

%% helper
function val = safeGetField(s, parts)
    % returns [] if missing
    try
        val = getfield(s, parts{:});  % expanded syntax
    catch
        val = [];
    end
end
