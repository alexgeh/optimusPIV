function waitForDownloadCycle(logPath, timeoutSec)
    % Waits until the C++ program has fully saved the target recording index.
    % Utilizes the absolute 'n_recorded' count rather than transient states.
    
    global recIdx;
    
    % Fallback if recIdx isn't initialized yet
    if isempty(recIdx)
        recIdx = 1; 
    end

    fprintf('Waiting for recording cycle %d to complete...\n', recIdx);
    tStart = tic;

    while toc(tStart) < timeoutSec
        try
            txt = fileread(logPath);
            log = jsondecode(txt);

            % Check if the absolute number of completed recordings meets our target
            if isfield(log, 'n_recorded') && log.n_recorded >= recIdx
                fprintf('Download and save for cycle %d finished.\n', recIdx);
                return;  % Exit the wait loop successfully
            end
            
        catch ME
            % This catch block is vital, as C++ might be mid-write 
            % (file lock/empty file) when MATLAB attempts to read it.
            % We suppress the warning to avoid console spam during a collision.
        end
        
        pause(0.5);
    end

    error('Timeout waiting for download cycle %d to complete.', recIdx);
end
