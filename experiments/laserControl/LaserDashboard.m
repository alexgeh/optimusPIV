classdef LaserDashboard < handle
    % LASERDASHBOARD Comprehensive Live UI for the DM40 Laser
    
    properties
        LaserObj
        UIFig
        MainLayout  
        UITimer
        BtnShutdown % NEW: Emergency shutdown button
        
        % Tables
        TabParams
        TabFlags
        TabFaults
        TabAlarms
    end
    
    methods
        function obj = LaserDashboard(laserObj)
            obj.LaserObj = laserObj;
            obj.buildUI();
            
            obj.UITimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 1.0, ...
                'Name', 'LaserPollTimer', ...
                'TimerFcn', @(~,~) obj.updateUI());
            
            start(obj.UITimer);
        end
        
        function delete(obj)
            if ~isempty(obj.UITimer) && isvalid(obj.UITimer)
                stop(obj.UITimer);
                delete(obj.UITimer);
            end
            if ~isempty(obj.UIFig) && isvalid(obj.UIFig)
                delete(obj.UIFig);
            end
            obj.LaserObj = []; 
            fprintf('Dashboard and background timers safely terminated.\n');
        end
        
        function updateUI(obj)
            if ~isvalid(obj.UIFig), return; end
            if isempty(obj.LaserObj) || ~isvalid(obj.LaserObj), return; end
            if obj.LaserObj.IsBusy, return; end 
            
            try
                stats = obj.LaserObj.readDetailedStatus('both');
                amps = obj.LaserObj.getCurrent('both');
                
                % --- RED ALERT SAFETY MODE ---
                isAlert = false;
                for i = 1:2
                    if obj.LaserObj.State(i).ShutterOpen || ...
                       obj.LaserObj.State(i).DiodeOn || ...
                       obj.LaserObj.State(i).SetCurrent > 0.0 || ...
                       amps(i) > 1.0
                        isAlert = true;
                    end
                end
                
                if isAlert
                    alertColor = [1, 0.4, 0.4]; 
                    obj.UIFig.Color = alertColor;
                    obj.MainLayout.BackgroundColor = alertColor;
                else
                    safeColor = [0.94, 0.94, 0.94]; 
                    obj.UIFig.Color = safeColor;
                    obj.MainLayout.BackgroundColor = safeColor;
                end
                
                onoff = {'⚪ OFF', '🟢 ON'};
                okflt = {'✅ OK', '❌ FAULT'};
                okalm = {'✅ OK', '⚠️ ALARM'};
                intext = {'INTERNAL', 'EXTERNAL'};
                
                % NEW: Safety alert colors for core states
                shutAlert = {'🟢 CLOSED', '🔴 OPEN'};
                lddAlert  = {'🟢 OFF', '🔴 ON'};
                
                getOnOff = @(s, f) onoff{s.(f) + 1};
                getFlt   = @(s, f) okflt{s.(f) + 1};
                getAlm   = @(s, f) okalm{s.(f) + 1};
                getAny   = @(arr)  okflt{any(arr) + 1};
                getExt   = @(val)  intext{val + 1};
                
                % 1. REORDERED LASER PARAMETERS
                pData = cell(7, 2);
                for i = 1:2
                    pData{1,i} = sprintf('%.2f A', amps(i));
                    pData{2,i} = sprintf('%.2f A', obj.LaserObj.State(i).SetCurrent);
                    pData{3,i} = shutAlert{stats(i).StatusFlags.ShutterEnabled + 1};
                    pData{4,i} = lddAlert{stats(i).StatusFlags.LDDOn + 1};
                    
                    % PRF Frequency display logic
                    if obj.LaserObj.State(i).PRFSourceExt
                        pData{5,i} = sprintf('%d Hz (External)', obj.LaserObj.State(i).PRFHz);
                    else
                        pData{5,i} = sprintf('%d Hz', obj.LaserObj.State(i).PRFHz);
                    end
                    
                    pData{6,i} = getExt(obj.LaserObj.State(i).PRFSourceExt);
                    pData{7,i} = getExt(obj.LaserObj.State(i).GateSourceExt);
                end
                obj.TabParams.Data = pData;
                
                % 2. UPDATED STATUS FLAGS
                fData = cell(7, 2);
                for i = 1:2
                    fData{1,i} = stats(i).SystemState;
                    fData{2,i} = getOnOff(stats(i).StatusFlags, 'PowerOn');
                    fData{3,i} = getOnOff(stats(i).StatusFlags, 'KeySwitch');
                    fData{4,i} = getOnOff(stats(i).StatusFlags, 'QSWOn');
                    fData{5,i} = getOnOff(stats(i).StatusFlags, 'ShutterInterlock');
                    fData{6,i} = getOnOff(stats(i).StatusFlags, 'LDDInterlock');
                    fData{7,i} = getOnOff(struct('V', obj.LaserObj.State(i).FPKEnabled), 'V');
                end
                obj.TabFlags.Data = fData;
                
                % 3. SYSTEM FAULTS
                fltData = cell(9, 2);
                for i = 1:2
                    fltData{1,i} = getFlt(stats(i).SystemFaults, 'Memory');
                    fltData{2,i} = getFlt(stats(i).SystemFaults, 'SDCard');
                    fltData{3,i} = getFlt(stats(i).SystemFaults, 'BoardComm');
                    fltData{4,i} = getFlt(stats(i).SystemFaults, 'BoardState');
                    fltData{5,i} = getFlt(stats(i).SystemFaults, 'ControlBoard');
                    fltData{6,i} = getFlt(stats(i).SystemFaults, 'LDDInterlock');
                    fltData{7,i} = getFlt(stats(i).SystemFaults, 'ActualCurrent');
                    fltData{8,i} = getFlt(stats(i).SystemFaults, 'Settings');
                    fltData{9,i} = getAny(stats(i).TempFaultsRaw);
                end
                obj.TabFaults.Data = fltData;
                
                % 4. GENERAL ALARMS
                aData = cell(7, 2);
                for i = 1:2
                    aData{1,i} = getAlm(stats(i).GeneralAlarms, 'LDD1');
                    aData{2,i} = getAlm(stats(i).GeneralAlarms, 'LDD2');
                    aData{3,i} = getAlm(stats(i).GeneralAlarms, 'QSW');
                    aData{4,i} = getAlm(stats(i).GeneralAlarms, 'Flow');
                    aData{5,i} = getAlm(stats(i).GeneralAlarms, 'Wet');
                    aData{6,i} = getAlm(stats(i).GeneralAlarms, 'Humidity');
                    aData{7,i} = getAlm(stats(i).GeneralAlarms, 'HFSync');
                end
                obj.TabAlarms.Data = aData;
                
            catch
                % Ignore polling faults
            end
        end
        
        function buildUI(obj)
            obj.UIFig = uifigure('Name', 'DM40 Live Dashboard', 'Position', [100, 100, 450, 900], ...
                'CloseRequestFcn', @(~,~) obj.delete());

            % Added a row for the button
            obj.MainLayout = uigridlayout(obj.UIFig, [9, 1]);
            obj.MainLayout.RowHeight = {35, 25, '1.2x', 25, '1.2x', 25, '1.5x', 25, '1.2x'};

            % --- SHUTDOWN BUTTON ---
            obj.BtnShutdown = uibutton(obj.MainLayout, ...
                'Text', 'Safe Software Shutdown (Not an E-Stop)', ...
                'BackgroundColor', [0.9, 0.6, 0.2], ... % Amber/Orange instead of red
                'FontColor', 'k', ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) obj.LaserObj.shutdown('both', true));

            uilabel(obj.MainLayout, 'Text', '--- LASER PARAMETERS ---', 'FontWeight', 'bold');
            pRows = {'Actual Current', 'Set Current', 'Shutter Status', 'LDD Status', 'PRF Frequency', 'PRF Source', 'Gate Source'};
            obj.TabParams = obj.createTable(obj.MainLayout, pRows);

            uilabel(obj.MainLayout, 'Text', '--- STATUS FLAGS ---', 'FontWeight', 'bold');
            fRows = {'System State', 'Power', 'Key Switch', 'QSW Enabled', 'Shutter Interlock', 'LDD Interlock', 'FPK Enabled'};
            obj.TabFlags = obj.createTable(obj.MainLayout, fRows);
            
            uilabel(obj.MainLayout, 'Text', '--- SYSTEM FAULTS ---', 'FontWeight', 'bold');
            fltRows = {'Memory', 'SD Card', 'Board Comm', 'Board State', 'Control Board', 'LDD Interlock', 'Actual Current', 'Settings', 'Any Temp Fault'};
            obj.TabFaults = obj.createTable(obj.MainLayout, fltRows);
            
            uilabel(obj.MainLayout, 'Text', '--- GENERAL ALARMS ---', 'FontWeight', 'bold');
            aRows = {'LDD 1', 'LDD 2', 'QSW', 'Flow', 'Wet', 'Humidity', 'HF Sync'};
            obj.TabAlarms = obj.createTable(obj.MainLayout, aRows);
        end
        
        function t = createTable(~, parentLayout, rowNames)
            t = uitable(parentLayout);
            t.ColumnName = {'Head 0', 'Head 1'};
            t.RowName = rowNames;
            t.ColumnWidth = {'1x', '1x'};
            t.RowStriping = 'on';
        end
    end
end
