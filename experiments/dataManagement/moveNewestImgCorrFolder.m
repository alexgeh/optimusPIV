function moveNewestImgCorrFolder(sourceDir, destDir, newBaseName)
    % moveAndRenameNewestImgCorrFolder(sourceDir, destDir, newBaseName)
    %
    % Finds the newest folder in sourceDir containing '_ImgCorr)' in its name,
    % moves it to destDir with a new name specified by newBaseName,
    % and also handles the associated .set file.
    
    % List folders matching pattern
    dirInfo = dir(fullfile(sourceDir, '*_ImgCorr)*'));
    dirInfo = dirInfo([dirInfo.isdir]);

    if isempty(dirInfo)
        error('No folders containing "_ImgCorr)" found in %s.', sourceDir);
    end

    % Find newest folder
    [~, newestIdx] = max([dirInfo.datenum]);
    oldFolderName = dirInfo(newestIdx).name;
    oldFolderPath = fullfile(sourceDir, oldFolderName);

    % Rename and construct new folder and file names
    % newFolderName = [newBaseName, '_ImgCorr)'];
    % newFolderPath = fullfile(destDir, newFolderName);
    newFolderPath = fullfile(destDir, newBaseName);

    % Copy folder to destination with new name
    copyStatus = copyfile(oldFolderPath, newFolderPath);
    if ~copyStatus
        error('Failed to copy folder from %s to %s.', oldFolderPath, newFolderPath);
    end

    % Delete original folder
    rmdir(oldFolderPath, 's');

    % Handle associated .set file
    % Assume original .set file has the same name as the folder (excluding the closing ')')
    oldSetFile = fullfile(sourceDir, [oldFolderName, '.set']);
    newSetFile = fullfile(destDir, [newBaseName, '.set']);

    if exist(oldSetFile, 'file')
        movefile(oldSetFile, newSetFile);
    else
        warning('Corresponding .set file not found: %s', oldSetFile);
    end

    fprintf('Moved and renamed folder to: %s\n', newFolderPath);
    fprintf('Moved and renamed .set file to: %s\n', newSetFile);
end
