function write_experiment_config(root_dir, PIV_settings, COM_settings, davis_exe, davis_project_source, verbose)
%WRITE_EXPERIMENT_CONFIG Saves experiment config to JSON.
%
% Parameters:
%   root_dir (char/string): Root data directory.
%   PIV_settings (struct): Acquisition settings.
%   COM_settings (struct): Communication settings (equipment).
%   verbose (logical): If true, prints summary table to console.

    if nargin < 3
        verbose = false;
    end

    % Define subdirectories
    raw_PIV_dir = fullfile(root_dir, 'raw_PIV');
    proc_PIV_dir = fullfile(root_dir, 'proc_PIV');
    analysis_PIV_dir = fullfile(root_dir, 'analysis_PIV');
    davis_proj_dir = fullfile(root_dir, 'davis_project', 'optimusPIV');
    davis_templ_dir = fullfile(davis_proj_dir, 'template');
    davis_templ_mraw = fullfile(davis_templ_dir, 'Camera2.mraw');
    davis_lvs_file = fullfile(davis_proj_dir, 'funkyStereo.OperationList.lvs');
    davis_set_file = fullfile(davis_proj_dir, 'template.set');
    log_path = fullfile(raw_PIV_dir, "recording_log.json");
    proc_log = fullfile(proc_PIV_dir, "processing_log.json");

    % Create config struct
    config = struct( ...
        'root_dir', root_dir, ...
        'davis_exe', davis_exe, ...
        'davis_project_source', davis_project_source, ...
        'raw_PIV_dir', raw_PIV_dir, ...
        'proc_PIV_dir', proc_PIV_dir, ...
        'analysis_PIV_dir', analysis_PIV_dir, ...
        'davis_proj_dir', davis_proj_dir, ...
        'davis_templ_dir', davis_templ_dir, ...
        'davis_templ_mraw', davis_templ_mraw, ...
        'davis_lvs_file', davis_lvs_file, ...
        'davis_set_file', davis_set_file, ...
        'log_path', log_path, ...
        'proc_log', proc_log, ...
        'PIV_settings', PIV_settings, ...
        'COM_settings', COM_settings ...
    );

    % Write to JSON
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    if ~exist(root_dir, 'dir')
        mkdir(root_dir);
    end
    jsonFilePath = fullfile(root_dir, 'experiment_config.json');
    fid = fopen(jsonFilePath, 'w');
    if fid == -1
        error('Cannot create JSON file: %s', jsonFilePath);
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);

    if verbose
        fprintf('\nExperiment Configuration Written to: %s\n', jsonFilePath);
        print_struct_table(config, 'Top-Level Paths');
    end
end
