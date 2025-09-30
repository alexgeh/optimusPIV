function initRecordingLog(logPath)
% initRecordingLog - Initializes a recording log JSON file.
% Usage: initRecordingLog('C:\path\to\experiment_log.json');

    log.cases = struct();             % No cases yet
    log.n_recorded = 0;
    log.status = "initializing";     % Placeholder until system is ready

    % Ensure parent directory exists
    logDir = fileparts(logPath);
    if ~isfolder(logDir)
        mkdir(logDir);
    end

    % Encode and pretty-print JSON
    jsonCompact = jsonencode(log);
    jsonStruct = jsondecode(jsonCompact);
    jsonPretty = jsonencode(jsonStruct, 'PrettyPrint', true);

    % Save to file
    fid = fopen(logPath, 'w');
    if fid == -1
        error("Could not create log file: %s", logPath);
    end
    fwrite(fid, jsonPretty, 'char');
    fclose(fid);
end
