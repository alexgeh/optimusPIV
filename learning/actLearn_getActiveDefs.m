function defs = actLearn_getActiveDefs(allDefs, activeNames, defType)
% actLearn_getActiveDefs  Select active input/output definitions by name.

    if nargin < 3
        defType = 'definition';
    end

    activeNames = cellstr(activeNames);
    allNames = {allDefs.name};
    idxOrder = NaN(1, numel(activeNames));

    for j = 1:numel(activeNames)
        idx = find(strcmp(allNames, activeNames{j}), 1, 'first');
        if isempty(idx)
            error('Unknown active %s name: %s', defType, activeNames{j});
        end
        idxOrder(j) = idx;
    end

    defs = allDefs(idxOrder);
end
