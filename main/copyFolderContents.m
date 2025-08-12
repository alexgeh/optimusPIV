function copyFolderContents(srcFolder, dstFolder)
% copyFolderContents - Recursively copies all contents from srcFolder to dstFolder.
%
% Usage:
%   copyFolderContents('sourcePath', 'destinationPath')

    % Validate input
    if ~isfolder(srcFolder)
        error('Source folder "%s" does not exist.', srcFolder);
    end

    % Ensure destination exists
    if ~isfolder(dstFolder)
        mkdir(dstFolder);
    end

    % Get list of all files and folders in source
    entries = dir(srcFolder);

    % Skip '.' and '..'
    entries = entries(~ismember({entries.name}, {'.', '..'}));

    for i = 1:length(entries)
        srcPath = fullfile(srcFolder, entries(i).name);
        dstPath = fullfile(dstFolder, entries(i).name);

        if entries(i).isdir
            % Recursively copy subdirectory
            copyFolderContents(srcPath, dstPath);
        else
            % Copy file
            copyfile(srcPath, dstPath);
        end
    end
end
