function ensureTopLevelFolder(folderPath)
% ensureTopLevelFolder - Creates a folder only if its parent exists.
% Throws an error if any intermediate folder is missing.

    % Normalize path
    folderPath = char(folderPath);  % Ensure string input works

    % Check if folder already exists
    if isfolder(folderPath)
        return;  % Nothing to do
    end

    % Get parent folder
    parentFolder = fileparts(folderPath);

    % Check that the parent folder exists
    if ~isfolder(parentFolder)
        error('Parent folder "%s" does not exist. Aborting folder creation.', parentFolder);
    end

    % Create only the last layer
    mkdir(folderPath);
end
