function waitForDownloadCycle(logPath, timeoutSec)
    % Waits until the log status becomes 'downloading' and then changes to something else.
    % Throws error if it takes longer than timeoutSec.

    fprintf("Waiting for download to begin...\n");
    tStart = tic;
    hasEnteredDownloading = false;

    while toc(tStart) < timeoutSec
        try
            txt = fileread(logPath);
            log = jsondecode(txt);

            if isfield(log, "status")
                if strcmp(log.status, "downloading")
                    if ~hasEnteredDownloading
                        fprintf("Download started...\n");
                        hasEnteredDownloading = true;
                    end
                elseif hasEnteredDownloading
                    fprintf("Download finished.\n");
                    return;  % Finished waiting once it changes from 'downloading'
                end
            end
        catch ME
            warning("Error reading log: %s", ME.message);
        end
        pause(0.5);
    end

    warning("Timeout waiting for download cycle to complete.");
end

