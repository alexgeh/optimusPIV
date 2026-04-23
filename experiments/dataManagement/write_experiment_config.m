function jsonFilePath = write_experiment_config(root_dir, PIV_settings, COM_settings, EVAL_settings, OPT_settings, davis_exe, davis_project_source, options)
%% WRITE_EXPERIMENT_CONFIG Saves experiment config to JSON.
%
% Required Parameters:
%   root_dir (string): Root data directory.
%   PIV_settings (struct): Acquisition settings.
%   COM_settings (struct): Communication settings (equipment).
%   EVAL_settings (struct): Flow evaluation settings and weights.
%   OPT_settings (struct): Optimization bounds and loop parameters.
%   davis_exe (string): Path to DaVis executable.
%   davis_project_source (string): Path to source DaVis project.
%
% Optional Name-Value Parameters:
%   davis_proj_name (string): Name of the DaVis project (default: "optimusPivDfd")
%   camera_index (integer): Camera number for the .mraw template (default: 1)
%   davis_lvs_name (string): Prefix for the OperationList.lvs file (default: "twoDimGPU_200")
%   verbose (logical): If true, prints summary table to console (default: false)

    arguments
        root_dir string
        PIV_settings struct
        COM_settings struct
        EVAL_settings struct
        OPT_settings struct
        davis_exe string
        davis_project_source string
        options.davis_proj_name string = "optimusPivDfd"
        options.camera_index (1,1) double {mustBeInteger, mustBePositive} = 1
        options.davis_lvs_name string = "twoDimGPU_200"
        options.verbose (1,1) logical = false
    end

    % Define subdirectories using parameterized inputs
    raw_PIV_dir = fullfile(root_dir, 'raw_PIV');
    proc_PIV_dir = fullfile(root_dir, 'proc_PIV');
    analysis_PIV_dir = fullfile(root_dir, 'analysis_PIV');
    
    % Parameterized DaVis paths
    davis_proj_dir = fullfile(root_dir, 'davis_project', options.davis_proj_name);
    davis_templ_dir = fullfile(davis_proj_dir, 'template');
    davis_templ_mraw = fullfile(davis_templ_dir, sprintf('Camera%d.mraw', options.camera_index));
    davis_lvs_file = fullfile(davis_proj_dir, sprintf('%s.OperationList.lvs', options.davis_lvs_name));
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
        'COM_settings', COM_settings, ...
        'EVAL_settings', EVAL_settings, ...
        'OPT_settings', OPT_settings ...
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

    if options.verbose
        fprintf('\nExperiment Configuration Written to: %s\n', jsonFilePath);
        print_struct_table(config, 'Top-Level Paths'); 
    end
end
