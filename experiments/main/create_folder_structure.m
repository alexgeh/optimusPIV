function create_folder_structure(config)
    %% Create project folder structure
    ensureTopLevelFolder(config.raw_PIV_dir);
    ensureTopLevelFolder(config.proc_PIV_dir);
    ensureTopLevelFolder(config.analysis_PIV_dir);
    ensureTopLevelFolder(fullfile(config.root_dir, "davis_project"));
    % Copy over source Davis project:
    copyFolderContents(config.davis_project_source, fullfile(config.root_dir, "davis_project"));
end

