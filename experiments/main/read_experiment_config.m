function config = read_experiment_config(jsonFilePath, verbose)
%READ_EXPERIMENT_CONFIG Loads experiment config from JSON file.
%
% Parameters:
%   jsonFilePath (char/string): Path to JSON config file.
%   verbose (logical): If true, prints summary table to console.
%
% Returns:
%   config (struct): Loaded experiment configuration.

    if nargin < 2
        verbose = false;
    end

    if ~isfile(jsonFilePath)
        error('JSON file not found: %s', jsonFilePath);
    end

    % Read file
    fid = fopen(jsonFilePath, 'r');
    raw = fread(fid, inf, 'char=>char')';
    fclose(fid);

    % Decode JSON
    config = jsondecode(raw);

    if verbose
        fprintf('\nExperiment Configuration Loaded from: %s\n', jsonFilePath);
        print_struct_table(config, 'Top-Level Paths');
    end
end
