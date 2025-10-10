%% Small test script for the ATG CLI Matlab wrapper

AtgExe = "R:\ENG_Breuer_Shared\agehrke\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";
outDir = "C:\Users\agehrke\Downloads\ATG_rec";
logFile = fullfile(outDir, "ATG_rec_" + string(datetime('now','Format','yyyyMMdd_HHmmss')) + ".csv");

atg = ATGController(AtgExe, outDir);
atg.connect();
% atg.outDirectory = outDir;
pause(3)


%%
nodeIdx = 0:14;

% Move to static position
atg.gozero(nodeIdx);
pause(1)
atg.log(nodeIdx, 20, 10, logFile);
pause(1);
atg.static(nodeIdx, 22.5);
% atg.waitForResponse('reached target', 10);
pause(5);
atg.sethome(nodeIdx);
pause(2)
atg.capturehomes(nodeIdx);
pause(2)

% atg.velrun(nodeIdx, 60, 5);
atg.bf(nodeIdx, 45, 2, 5);
pause(15);

% Stop logging and motion, bring motors back to zero position
atg.stoplog();
atg.stopnodes(nodeIdx);
atg.gozero(nodeIdx);
pause(1)
atg.sethome(nodeIdx);
pause(1)
atg.capturehomes(nodeIdx);
pause(1)


%%
clear atg  % Automatically calls delete() to shut down the CLI
