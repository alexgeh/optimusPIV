function proc_log = read_processing_log(jsonFilePath, verbose)
%READ_EXPERIMENT_CONFIG Loads experiment processing log from JSON file.
%
% Parameters:
%   jsonFilePath (char/string): Path to JSON recording log file.
%   verbose (logical): If true, prints summary table to console.
%
% Returns:
%   rec_log (struct): Recording log.

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
    proc_log = jsondecode(raw);

    if verbose
        fprintf('\nRecording Log Loaded from: %s\n', jsonFilePath);
        print_struct_table(proc_log, 'Top-Level Paths');
    end
end
