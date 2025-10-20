%% Small test script for the ATG CLI Matlab wrapper

% AtgExe = "R:\ENG_Breuer_Shared\agehrke\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";
AtgExe = "C:\Users\agehrke\Downloads\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";
outDir = "C:\Users\agehrke\Downloads\ATG_rec";
logFile = fullfile(outDir, "ATG_rec_" + string(datetime('now','Format','yyyyMMdd_HHmmss')) + ".csv");


%% Setup and connect
maxRpm = 1200; % Maximum rotation rate [rpm]
maxRpmPerS = 10000; % Maximum rotation acceleration [rpm/s]
homeRpm = 50; % Lower rotation rate for homing and static motions [rpm]
homeRpmPerS = 500; % Lower rotation acceleration for homing and static motions [rpm/s]

controlRate = 20; % Control tick period [ms] (default: 20ms)

shortCmdWait = 2; % Time the script is pausing between issuing short execution commands [s] (e.g. changing max velocity)
longCmdWait = 5; % Time the script is pausing between issuing long execution commands [s] (e.g. zeroing or connecting to board)

allNodeIdx = 0:14;

atg = ATGController(AtgExe, outDir);
atg.connect();
% atg.outDirectory = outDir;
pause(longCmdWait)

atg.tick(controlRate);
pause(shortCmdWait)
atg.vel(homeRpm);
pause(shortCmdWait)
atg.acc(homeRpmPerS);
pause(shortCmdWait)

atg.gozero(allNodeIdx);
pause(longCmdWait)


%%
nodeIdx = 0:14;

offset = 0;  % Offset starting angle [deg]
pitchAmpl = 60; % Pitching amplitude [deg]
pitchFreq = 8;  % Pitching frequency [Hz]
pitchDur = 10;  % Pitching duration [s]

% Move to static position
% atg.gozero(nodeIdx);
% pause(5)
% atg.log(nodeIdx, 20, 30, logFile);
% pause(shortCmdWait)
% atg.static(nodeIdx, offset);
% atg.waitForResponse('reached target', 10);
% pause(longCmdWait);
% atg.sethome(allNodeIdx);
% pause(shortCmdWait)
% atg.capturehomes(allNodeIdx);
% pause(shortCmdWait)

atg.vel(maxRpm);
pause(shortCmdWait)
atg.acc(maxRpmPerS);
pause(shortCmdWait)
atg.bfsync(nodeIdx, pitchAmpl, pitchFreq, pitchDur, offset);
pause(5)
disp(">>> !!! Record NOW !!! <<<")
pause(pitchDur);

% Stop logging and motion, bring motors back to zero position
% atg.stoplog();
% pause(shortCmdWait)
% atg.stopnodes(nodeIdx);
% pause(shortCmdWait)

atg.vel(homeRpm);
pause(shortCmdWait)
atg.acc(homeRpmPerS);
pause(shortCmdWait)

atg.gozero(nodeIdx);
pause(longCmdWait)
% atg.sethome(nodeIdx);
% pause(2)
% atg.capturehomes(nodeIdx);
% pause(2)


%%
clear atg  % Automatically calls delete() to shut down the CLI
