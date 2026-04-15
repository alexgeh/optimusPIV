% =========================================================================
% DM40Control
% 
% Author:       Alexander Gehrke / Breuer Lab
% Date:         April 10, 2026
% Version:      1.0.0
% Description:  Controls a Photonics DM40-DH Dual-Head Laser via RS-232.
%               Features detailed status tracking, safety interlocks, 
%               full telemetry, and smart-polling hardware confirmation.
% =========================================================================

classdef DM40Control < handle
    
    properties
        % Toggle false in production scripts to mute routine console output
        Verbose = true; 
    end
    
    properties (SetAccess = private)
        PortName
        BaudRate
        SerialObj
        
        IsBusy = false; % Prevents serial collisions between command line and UI
        
        % State tracking array. Index 1 = Head 0, Index 2 = Head 1.
        State
    end
    
    methods
        % --- Constructor / Destructor ---
        function obj = DM40Control(portName, baudRate)
            if nargin < 2
                baudRate = 115200;
            end
            obj.PortName = portName;
            obj.BaudRate = baudRate;
            
            obj.State = repmat(struct(...
                'ShutterOpen', false, 'DiodeOn', false, 'Current', 0.0, ...
                'SetCurrent', 0.0, 'PRFSourceExt', false, 'GateSourceExt', false, ...
                'FPKEnabled', false, 'PRFHz', 0), 1, 2);
            
            % Critical outputs (Verbose flag bypassed)
            fprintf('Connecting to DM40 Laser on %s...\n', obj.PortName);
            obj.SerialObj = serialport(obj.PortName, obj.BaudRate, ...
                "DataBits", 8, "Parity", "none", "StopBits", 1, "Timeout", 5);
            configureTerminator(obj.SerialObj, "CR");
            pause(1); 
            fprintf('Connection established.\n');
            
            obj.vprint('Syncing initial hardware state...\n');
            obj.syncState('both');
        end
        
        function delete(obj)
            if ~isempty(obj.SerialObj) && isvalid(obj.SerialObj)
                delete(obj.SerialObj);
                fprintf('Laser connection closed.\n'); % Critical output
            end
        end
        
        % ==========================================
        % --- CONVENIENCE METHODS (USER FACING) ---
        % ==========================================
        
        function openShutter(obj, headAddr)
            if nargin < 2, headAddr = 'both'; end
            obj.setShutter(1, headAddr);
        end
        
        function closeShutter(obj, headAddr)
            if nargin < 2, headAddr = 'both'; end
            obj.setShutter(0, headAddr);
        end
        
        function turnOnDiode(obj, headAddr)
            if nargin < 2, headAddr = 'both'; end
            obj.setDiode(1, headAddr);
        end
        
        function turnOffDiode(obj, headAddr)
            if nargin < 2, headAddr = 'both'; end
            obj.setDiode(0, headAddr);
        end
        
        function shutdown(obj, headAddr, fromUI)
            % Catch-all safe shutdown sequence
            if nargin < 3, fromUI = false; end
            if nargin < 2, headAddr = 'both'; end

            if fromUI
                fprintf('\n--- MANUAL UI SOFTWARE SHUTDOWN TRIGGERED ---\n');
            else
                obj.vprint('\nInitiating routine software shutdown...\n');
            end

            try
                % 1. Command current to 0
                obj.setCurrent(0, headAddr);

                % 2. Turn off diodes (This safely waits for current to ramp down!)
                obj.turnOffDiode(headAddr);

                % 3. Close shutters
                obj.closeShutter(headAddr);

                if fromUI
                    fprintf('--- UI SOFTWARE SHUTDOWN COMPLETE ---\n\n');
                else
                    obj.vprint('Routine software shutdown complete.\n\n');
                end
            catch ME
                fprintf('WARNING: Shutdown sequence encountered an error: %s\n', ME.message);
            end
        end
        
        % ==========================================
        % --- CORE LOGIC & SAFETY INTERLOCKS ---
        % ==========================================
        
        function setShutter(obj, state, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('04');
            
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                
                if state == 0 && obj.State(idx).DiodeOn
                    error('SAFETY INTERLOCK: Cannot close Head %d shutter while Diode is ON!', addr);
                end
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, state);
                obj.checkWriteSuccess(writeData, 'Shutter');
                
                % Smart Polling: Wait for mechanical actuation
                tStart = tic;
                stateConfirmed = false;
                while toc(tStart) < 5.0
                    [~, readData] = obj.queryDevice(addr, cmdCode);
                    if readData(1) == state
                        stateConfirmed = true;
                        break;
                    end
                    pause(0.1); 
                end
                
                if ~stateConfirmed
                    error('HARDWARE TIMEOUT: Head %d Shutter failed to reach state %d within 5 seconds!', addr, state);
                end
                
                obj.State(idx).ShutterOpen = (state == 1);
                stateStr = {'CLOSED', 'OPEN'};
                obj.vprint('Head %d: Shutter is %s.\n', addr, stateStr{state+1});
            end
        end
        
        function setDiode(obj, state, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('10');
            
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                
                if state == 1
                    if ~obj.State(idx).ShutterOpen
                        error('SAFETY INTERLOCK: Cannot turn ON Head %d Diode while Shutter is CLOSED!', addr);
                    end
                else
                    % --- RAMP-DOWN STALL WATCHDOG ---
                    actualCurrent = obj.getCurrent(addr);
                    if actualCurrent > 1.0
                        obj.vprint('Head %d: Waiting for current to drop before disabling diode...\n', addr);
                        
                        lastProgressAmps = actualCurrent;
                        tStall = tic;
                        warned = false;
                        
                        while actualCurrent > 1.0
                            % Bypass verbose flag for stall warnings so user knows script isn't dead
                            if toc(tStall) > 3.0 && ~warned
                                fprintf('WARNING: Head %d current ramp-down is taking longer than expected (%.2f A). Waiting...\n', addr, actualCurrent);
                                warned = true;
                            end
                            
                            if toc(tStall) > 6.0
                                error('HARDWARE STALL: Head %d current stuck around %.2f A. Aborting Diode OFF.', addr, actualCurrent);
                            end
                            
                            pause(0.5);
                            actualCurrent = obj.getCurrent(addr);
                            
                            % Reset stall timer if current drops by 0.3A (beating sensor noise)
                            if actualCurrent < (lastProgressAmps - 0.3)
                                lastProgressAmps = actualCurrent;
                                tStall = tic; 
                                warned = false;
                            end
                        end
                    end
                end
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, state);
                obj.checkWriteSuccess(writeData, 'Diode Enable');
                
                % Smart Polling: Wait for hardware registers to update
                tStart = tic;
                stateConfirmed = false;
                while toc(tStart) < 5.0
                    [~, readData] = obj.queryDevice(addr, cmdCode);
                    if readData(1) == state
                        stateConfirmed = true;
                        break;
                    end
                    pause(0.1);
                end
                
                if ~stateConfirmed
                    error('HARDWARE TIMEOUT: Head %d Diode failed to reach state %d within 5 seconds!', addr, state);
                end
                
                obj.State(idx).DiodeOn = (state == 1);
                stateStr = {'OFF', 'ON'};
                obj.vprint('Head %d: Diode is %s.\n', addr, stateStr{state+1});
            end
        end
        
        function setCurrent(obj, amps, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('11');
            
            isMax = false;
            if (ischar(amps) || isstring(amps)) && strcmpi(amps, 'max')
                isMax = true;
            elseif ~isnumeric(amps)
                error('Current must be a numeric value or ''max''.');
            end
            
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                
                if isMax
                    targetAmps = obj.getMaxCurrent(addr);
                    obj.vprint('Head %d: Max current queried as %.2f A.\n', addr, targetAmps);
                else
                    targetAmps = double(amps);
                end
                
                if targetAmps > 0.0
                    if ~obj.State(idx).ShutterOpen || ~obj.State(idx).DiodeOn
                        error('SAFETY INTERLOCK: Cannot ramp up Head %d current. Shutter OPEN and Diode ON required.', addr);
                    end
                end
                
                % Convert target amps to integer format required by protocol (x100)
                rawCurrent = uint16(targetAmps * 100);
                D1 = bitshift(rawCurrent, -8);  % Most Significant Byte
                D2 = bitand(rawCurrent, 255);   % Least Significant Byte
                
                obj.vprint('Head %d: Setting target current to %.2f A...\n', addr, targetAmps);
                [~, writeData] = obj.queryDevice(addr, cmdCode, [D1, D2]);
                obj.checkWriteSuccess(writeData, 'Set Current');
                
                obj.State(idx).SetCurrent = targetAmps;
            end
        end
        
        function amps = getCurrent(obj, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('12');
            
            amps = zeros(1, length(heads));
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                
                % Recombine MSB and LSB
                current_raw = bitor(bitshift(readData(1), 8), readData(2));
                amps(i) = current_raw / 100;
                
                obj.State(idx).Current = amps(i);
            end
        end
        
        function maxAmps = getMaxCurrent(obj, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('14'); 
            
            maxAmps = zeros(1, length(heads));
            for i = 1:length(heads)
                addr = heads(i);
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                max_raw = bitor(bitshift(uint16(readData(1)), 8), uint16(readData(2)));
                maxAmps(i) = double(max_raw) / 100.0;
            end
        end
        
        % ==========================================
        % --- ADDITIONAL LASER PARAMETERS ---
        % ==========================================
        
        function setPRFSource(obj, isExternal, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('23');
            
            actionStr = {'INTERNAL', 'EXTERNAL'};
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                obj.vprint('Head %d: Setting PRF Source to %s...\n', addr, actionStr{isExternal+1});
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, isExternal);
                obj.checkWriteSuccess(writeData, 'PRF Source');
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                obj.State(idx).PRFSourceExt = (readData(1) == 1);
            end
        end
        
        function setGateSource(obj, isExternal, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('24'); 
            
            actionStr = {'INTERNAL', 'EXTERNAL'};
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                obj.vprint('Head %d: Setting Gate Source to %s...\n', addr, actionStr{isExternal+1});
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, isExternal);
                obj.checkWriteSuccess(writeData, 'Gate Source');
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                obj.State(idx).GateSourceExt = (readData(1) == 1);
            end
        end
        
        function setFPK(obj, isEnabled, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('27'); 
            
            actionStr = {'DISABLED', 'ENABLED'};
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                obj.vprint('Head %d: Setting FPK to %s...\n', addr, actionStr{isEnabled+1});
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, isEnabled);
                obj.checkWriteSuccess(writeData, 'FPK');
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                obj.State(idx).FPKEnabled = (readData(1) == 1);
            end
        end
        
        function setPRF(obj, freqHz, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('21'); 
            
            if freqHz < 0 || freqHz > 1000000
                error('PRF frequency must be between 0 and 1,000,000 Hz');
            end
            
            % Split 32-bit frequency into three 8-bit bytes
            rawFreq = uint32(freqHz);
            D1 = bitand(bitshift(rawFreq, -16), 255); 
            D2 = bitand(bitshift(rawFreq, -8), 255);  
            D3 = bitand(rawFreq, 255);                
            
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                obj.vprint('Head %d: Setting PRF to %d Hz...\n', addr, freqHz);
                
                [~, writeData] = obj.queryDevice(addr, cmdCode, [D1, D2, D3]);
                obj.checkWriteSuccess(writeData, 'Set PRF');
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                actualFreq = bitor(bitshift(uint32(readData(1)), 16), ...
                             bitor(bitshift(uint32(readData(2)), 8), ...
                             uint32(readData(3))));
                             
                obj.State(idx).PRFHz = double(actualFreq);
            end
        end
        
        % ==========================================
        % --- DETAILED HARDWARE STATUS TRACKING ---
        % ==========================================
        
        function syncState(obj, headAddr)
            heads = obj.resolveHeads(headAddr);
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                obj.readDetailedStatus(addr);
                obj.getCurrent(addr); 
                
                [~, prfSrc]  = obj.queryDevice(addr, hex2dec('23'));
                [~, gateSrc] = obj.queryDevice(addr, hex2dec('24')); 
                [~, fpkEn]   = obj.queryDevice(addr, hex2dec('27'));   
                [~, prfVal]  = obj.queryDevice(addr, hex2dec('21'));  
                
                obj.State(idx).PRFSourceExt = (prfSrc(1) == 1);
                obj.State(idx).GateSourceExt = (gateSrc(1) == 1);
                obj.State(idx).FPKEnabled = (fpkEn(1) == 1);
                
                freq = bitor(bitshift(uint32(prfVal(1)), 16), ...
                       bitor(bitshift(uint32(prfVal(2)), 8), uint32(prfVal(3))));
                obj.State(idx).PRFHz = double(freq);
            end
            obj.vprint('Hardware state synchronization complete.\n');
        end
        
        function status = readDetailedStatus(obj, headAddr)
            heads = obj.resolveHeads(headAddr);
            cmdCode = hex2dec('0F');
            
            for i = 1:length(heads)
                addr = heads(i);
                idx = addr + 1;
                
                [~, readData] = obj.queryDevice(addr, cmdCode);
                D1 = readData(1); D2 = readData(2); D3 = readData(3);
                D4 = readData(4); D5 = readData(5);
                
                % --- D#1: System Status ---
                sysStat.PowerOn          = bitget(D1, 1) == 1;
                sysStat.KeySwitch        = bitget(D1, 3) == 1;
                sysStat.QSWOn            = bitget(D1, 5) == 1;
                sysStat.ShutterInterlock = bitget(D1, 6) == 1;
                sysStat.LDDInterlock     = bitget(D1, 7) == 1;
                
                % Overwrite lazy 0x0F bits with true individual head state
                [~, shutData] = obj.queryDevice(addr, hex2dec('04'));
                [~, dioData]  = obj.queryDevice(addr, hex2dec('10'));
                sysStat.ShutterEnabled = (shutData(1) == 1);
                sysStat.LDDOn          = (dioData(1) == 1);
                
                obj.State(idx).ShutterOpen = sysStat.ShutterEnabled;
                obj.State(idx).DiodeOn = sysStat.LDDOn;
                
                % --- D#2: System Faults ---
                faults.Memory         = bitget(D2, 1) == 1;
                faults.SDCard         = bitget(D2, 2) == 1;
                faults.BoardComm      = bitget(D2, 3) == 1;
                faults.BoardState     = bitget(D2, 4) == 1;
                faults.LDDInterlock   = bitget(D2, 5) == 1;
                faults.ActualCurrent  = bitget(D2, 6) == 1;
                faults.Settings       = bitget(D2, 7) == 1;
                faults.ControlBoard   = bitget(D2, 8) == 1;
                
                % --- D#3: General Alarms ---
                alarms.LDD1       = bitget(D3, 1) == 1;
                alarms.LDD2       = bitget(D3, 2) == 1;
                alarms.QSW        = bitget(D3, 3) == 1;
                alarms.Flow       = bitget(D3, 4) == 1;
                alarms.Wet        = bitget(D3, 5) == 1;
                alarms.Humidity   = bitget(D3, 6) == 1;
                alarms.HFSync     = bitget(D3, 7) == 1;
                
                % --- D#4 & D#5 ---
                tempFaults = logical(bitget(D4, 1:8));
                stateStrs = {'Initialization', 'Setup', 'Running', 'Standby', 'Soft Fault', 'Hard Fault'};
                if D5 >= 0 && D5 <= 5, sysState = stateStrs{D5 + 1}; else, sysState = sprintf('Unknown (%d)', D5); end
                
                status(i).HeadAddress = addr;
                status(i).SystemState = sysState;
                status(i).StatusFlags = sysStat;
                status(i).SystemFaults = faults;
                status(i).GeneralAlarms = alarms;
                status(i).TempFaultsRaw = tempFaults;
            end
            if length(heads) == 1, status = status(1); end
        end
    end
    
    methods (Access = private)
        % --- Internal Helper Methods ---
        
        function vprint(obj, varargin)
            % Internal wrapper to suppress output when Verbose is false
            if obj.Verbose
                fprintf(varargin{:});
            end
        end
        
        function heads = resolveHeads(~, headAddr)
            if nargin < 2 || isempty(headAddr) || (ischar(headAddr) && strcmpi(headAddr, 'both'))
                heads = [0, 1];
            else
                heads = headAddr;
            end
        end
        
        function checkWriteSuccess(~, dataBytes, cmdName)
            if dataBytes(1) ~= 0
                error('%s write command FAILED with error code 0x%02X.', cmdName, dataBytes(1));
            end
        end
        
        function [RW, dataBytes] = queryDevice(obj, addr, cmdCode, dataPayload)
            % Lock the serial port so background UI timers don't crash into foreground commands
            while obj.IsBusy
                pause(0.01); 
            end
            obj.IsBusy = true;
            
            try
                if nargin < 4
                    cmdStr = obj.buildCommand(addr, cmdCode); 
                else
                    cmdStr = obj.buildCommand(addr, cmdCode, dataPayload); 
                end
                writeline(obj.SerialObj, cmdStr);
                
                response = char(readline(obj.SerialObj));
                
                bytes = hex2dec(reshape(response, 2, []).');
                RW = bytes(1); N = bytes(2); dataBytes = bytes(5 : 5 + N - 1); 
            catch ME
                obj.IsBusy = false; % Always unlock on error
                rethrow(ME);
            end
            
            obj.IsBusy = false; % Unlock when done
        end
        
        function cmd = buildCommand(~, addr, cmdCode, dataByte)
            if nargin < 4
                payload = [uint8(1), uint8(0), uint8(addr), uint8(cmdCode)]; 
            else
                payload = [uint8(0), uint8(numel(dataByte)), uint8(addr), uint8(cmdCode), uint8(dataByte(:)')]; 
            end
            checksum = sum(payload);
            frame = [payload, bitshift(checksum, -8), bitand(checksum, 255)];
            cmd = char(upper(join(string(dec2hex(frame, 2)), "")));
        end
    end
end
