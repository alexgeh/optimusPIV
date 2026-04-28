function ensureTopLevelFolder(folderPath, safeRoot)
% ensureTopLevelFolder - Creates a folder safely.
% Usage 1: ensureTopLevelFolder(target) 
%          -> Creates ONLY if the immediate parent exists (Legacy behavior).
% Usage 2: ensureTopLevelFolder(target, safeRoot) 
%          -> Recursively creates target, BUT strictly requires safeRoot to exist first.

    folderPath = string(folderPath);  
    if isfolder(folderPath)
        return; 
    end

    % Mode 1: Default behavior (Single-level creation)
    if nargin < 2 || isempty(safeRoot)
        parentFolder = fileparts(folderPath);
        if ~isfolder(parentFolder)
            error('Parent folder "%s" does not exist. Aborting folder creation.', parentFolder);
        end
        mkdir(char(folderPath));
        
    % Mode 2: Recursive behavior with safety anchor
    else
        safeRoot = string(safeRoot);
        if ~isfolder(safeRoot)
            error('Safety Triggered: Anchor root "%s" does not exist. Aborting recursive creation.', safeRoot);
        end
        if ~startsWith(folderPath, safeRoot)
            error('Safety Triggered: Target folder is not inside the provided root.\nTarget: %s\nRoot: %s', folderPath, safeRoot);
        end
        mkdir(char(folderPath)); % Safe recursive creation
    end
end
