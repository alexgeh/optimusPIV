function M = actLearn_extractMatrixFromDB(optDB, keys)
% actLearn_extractMatrixFromDB  Return a numeric matrix for DB keys.
%
% This is a thin wrapper around DB_extractData. It avoids duplicating DB
% traversal logic while giving the active-learning code and analysis code the
% same matrix format.

    if isempty(keys)
        M = zeros(numel(optDB), 0);
        return
    end

    keys = cellstr(keys);

    if isempty(optDB)
        M = zeros(0, numel(keys));
        return
    end

    M = NaN(numel(optDB), numel(keys));
    for k = 1:numel(keys)
        vals = DB_extractData(optDB, keys{k});
        M(:,k) = vals(:);
    end
end
