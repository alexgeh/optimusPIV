function vals = DB_extractData(optDB, keys)
% DB_extractData  Extract one or more values from optDB for given key(s).
%
%   vals = DB_extractData(optDB, 'metrics.TI_mean')
%       -> numeric vector (NaN for missing)
%
%   vals = DB_extractData(optDB, {'metrics.TI_mean','metrics.u_rms','metrics.v_rms'})
%       -> struct with fields TI_mean, u_rms, v_rms (vectors)
%
%   vals = DB_extractData(optDB, {'metrics.TI_mean','metrics.u_rms'}, 'table')
%       -> table with variables TI_mean, u_rms
%
% The function automatically distinguishes between numeric-like and string-like
% content and fills missing values appropriately.

    if nargin < 2 || isempty(keys)
        vals = [];
        return;
    end

    % Support both string/cell input
    if ischar(keys) || isstring(keys)
        keys = cellstr(keys);
        singleMode = true;
    else
        singleMode = numel(keys) == 1;
    end

    % Extract each key individually using the existing logic
    nKeys = numel(keys);
    tmp = cell(1,nKeys);
    for k = 1:nKeys
        tmp{k} = extractOne(optDB, keys{k});
    end

    % Return type
    if singleMode
        vals = tmp{1};
    else
        % Create struct of results
        cleanNames = cellfun(@(k) matlab.lang.makeValidName(strrep(k,'.','_')), keys, 'UniformOutput', false);
        vals = cell2struct(tmp, cleanNames, 2);
    end
end


%% --- helper: extract one field vector (your current logic) ---
function vals = extractOne(optDB, key)
    if isempty(optDB)
        vals = [];
        return;
    end
    keyParts = strsplit(key, '.');
    n = numel(optDB);
    out = cell(n,1);
    isNumericLike = true;

    for i = 1:n
        v = safeGetField(optDB(i), keyParts);
        if isempty(v)
            out{i} = [];
            continue;
        end
        out{i} = v;
        if ~isnumeric(v) && ~islogical(v)
            isNumericLike = false;
        end
    end

    if isNumericLike
        vals = NaN(n,1);
        for i = 1:n
            if ~isempty(out{i})
                if islogical(out{i}) && isscalar(out{i})
                    vals(i) = double(out{i});
                elseif isnumeric(out{i}) && isscalar(out{i})
                    vals(i) = out{i};
                else
                    try
                        vals(i) = double(out{i}(1));
                    catch
                        vals(i) = NaN;
                    end
                end
            else
                vals(i) = NaN;
            end
        end
    else
        vals = strings(n,1);
        for i = 1:n
            if isempty(out{i})
                vals(i) = "";
            else
                try
                    vals(i) = string(out{i});
                catch
                    if ischar(out{i})
                        vals(i) = string(out{i});
                    elseif iscell(out{i})
                        vals(i) = string(out{i}{1});
                    else
                        vals(i) = "";
                    end
                end
            end
        end
    end
end


function val = safeGetField(s, parts)
    try
        val = getfield(s, parts{:});
    catch
        val = [];
    end
end
