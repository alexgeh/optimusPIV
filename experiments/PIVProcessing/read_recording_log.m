function rec_log = read_recording_log(jsonFilePath, verbose)
%READ_EXPERIMENT_CONFIG Loads experiment config from JSON file.
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
    rec_log = jsondecode(raw);

    if verbose
        fprintf('\nRecording Log Loaded from: %s\n', jsonFilePath);
        print_struct_table(rec_log, 'Top-Level Paths');
    end
end
