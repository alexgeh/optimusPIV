function runAtgSync_optPIV_grad(freq, ampl, offset, ampgrad, offsetgrad)
%% Run the active turbulence grid (ATG) for one iteration of the PIV
%  optimzation algorithm.
%
%  Alexander Gehrke - 20251014
%#ok<*GVMIS>

global bnc % Grab BNC object to trigger PIV system (laser)
global optPIV_settings
skipCycles = optPIV_settings.skipCycles;

AtgExe = "C:\Users\agehrke\Downloads\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";
% AtgExe = "R:\ENG_Breuer_Shared\agehrke\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";
outDir = "C:\Users\agehrke\Downloads\ATG_rec";
% logFile = fullfile(outDir, "ATG_rec_" + string(datetime('now','Format','yyyyMMdd_HHmmss')) + ".csv");


%% Control parameters
% Motor speed and acceleration:
maxRpm = 1200; % Maximum rotation rate [rpm]
maxRpmPerS = 10000; % Maximum rotation acceleration [rpm/s]
homeRpm = 50; % Lower rotation rate for homing and static motions [rpm]
homeRpmPerS = 100; % Lower rotation acceleration for homing and static motions [rpm/s]

controlRate = 20; % Control tick period [ms] (default: 20ms)
shortCmdWait = 2; % Time the script is pausing between issuing short execution commands [s] (e.g. changing max velocity)
longCmdWait = 5; % Time the script is pausing between issuing long execution commands [s] (e.g. zeroing or connecting to board)

allNodeIdx = 0:14; % Specify all nodes being used

triggerDelay = 7; % Skip first n cycles before triggering
% triggerDelay = skipCycles / freq; % Skip first n cycles before triggering
duration = 10 + triggerDelay;  % Motion duration [s]


%% Connect and set up ATG motor controller:
disp('---------------------------------------------------')
atg = ATGController(AtgExe, outDir);
atg.connect();
pause(longCmdWait)

% atg.tick(controlRate);
% pause(shortCmdWait)

% Home grid
atg.vel(homeRpm);
pause(shortCmdWait)
atg.acc(homeRpmPerS);
pause(shortCmdWait)
atg.gozero(allNodeIdx);
pause(longCmdWait)


%% Increase motor speed and acceleration limits & run the grid
% offset = -60;  % Offset starting angle [deg]
% pitchAmpl = 120; % Pitching amplitude [deg]
% pitchFreq = 1;  % Pitching frequency [Hz]

atg.vel(maxRpm);
pause(shortCmdWait)
atg.acc(maxRpmPerS);
pause(shortCmdWait)

% atg.bfsync(allNodeIdx, ampl, freq, duration, offset);
atg.bfsync_grad(allNodeIdx, ampl, freq, duration, offset, ampgrad, offsetgrad)
pause(triggerDelay)
bnc_software_trigger(bnc, 0)
pause(duration - triggerDelay + 5); % Wait some extra to make sure motion is done

% Stop logging and motion, bring motors back to zero position
% atg.stoplog();
% pause(shortCmdWait)
% atg.stopnodes(nodeIdx);
% pause(shortCmdWait)


%% Home grid and sever connection. 
%  More robust this way as sometimes controller will stop to respond.
atg.vel(homeRpm);
pause(shortCmdWait)
atg.acc(homeRpmPerS);
pause(shortCmdWait)

atg.gozero(allNodeIdx);
pause(longCmdWait)

clear atg  % Automatically calls delete() to shut down the CLI

disp('---------------------------------------------------')
end
