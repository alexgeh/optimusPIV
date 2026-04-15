%% DM40 Full Laser Ramp Cycle & Safety Test
clear; clc;

% 1. Connect to Laser 
% (This automatically queries 0x0F and Syncs State internally!)
laser = DM40Control('COM9'); 
laser.printStatus();

%%
try
    %% 2. Check System Health
    % Query Head 0 just to print the current state out of curiosity
    % head0_status = laser.readDetailedStatus(0);
    % fprintf('\nSystem State for Head 0 is: %s\n', head0_status.SystemState);
    % if ~head0_status.StatusFlags.KeySwitch
    %     warning('The physical key switch is OFF! Laser may not fire.');
    % end

    fprintf('Proceeding with Ramp Sequence...\n\n');

    %% 3. Setup Parameters
    % If using 'both', the class automatically iterates Head 0 and Head 1.
    targetHeads = 1; 
    targetAmps  = 17.65;
    
    %% 4. Prepare Laser for Firing (Order is enforced by safety interlocks)
    laser.setPRFSource(0, targetHeads);   % Set PRF to Internal (0)
    laser.setGateSource(0, targetHeads);   % Set PRF to Internal (0)
    laser.setPRF(100, targetHeads); % PRF frequency [Hz]
    
    % Use convenient wrappers
    laser.openShutter(targetHeads); 
    laser.turnOnDiode(targetHeads);    
    
    %% 5. Ramp Up Current
    laser.setCurrent(targetAmps, targetHeads);
    
    % Monitor current ramping up for 5 seconds
    fprintf('\n--- Monitoring Ramp UP ---\n');
    for i = 1:10
        amps = laser.getCurrent(targetHeads);
        fprintf('Current: %.2f A\n', amps(1)); % Prints Head 0 current
        pause(1);
    end
    
    %% 6. Hold/Fire
    fprintf('\nLaser is FIRING at target current. Holding for 5 seconds...\n');
    pause(5);
    
    %% 7. Ramp Down Current
    laser.setCurrent(0.0, targetHeads);
    
    % Monitor current ramping down for 5 seconds
    fprintf('\n--- Monitoring Ramp DOWN ---\n');
    for i = 1:10
        amps = laser.getCurrent(targetHeads);
        fprintf('Current: %.2f A\n', amps(1));
        pause(1);
    end
    
    %% 8. Shut down procedures (Order is enforced by safety interlocks)
    % Note: turnOffDiode() has a built in while loop that checks if current 
    % is < 1.0A before it allows itself to shut down!
    laser.turnOffDiode(targetHeads); 
    % pause(0.1)
    laser.closeShutter(targetHeads);  
    
    fprintf('\nFull cycle completed successfully!\n');
    
catch ME
    % Emergency Safety Fallback
    warning('An error occurred! Attempting emergency diode shutdown...');
    try
        laser.turnOffDiode('both');
    catch
        % ignore subsequent errors
    end
    rethrow(ME);
end

%% 9. Disconnect
% Cleanly sever the COM port connection
clear laser;
