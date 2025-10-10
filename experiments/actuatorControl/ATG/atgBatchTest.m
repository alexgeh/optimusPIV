%% ATG_Batch.m
% Runs single-vane sweeps at various RPMs using the ATG CLI.
% MATLAB equivalent of PowerShell script ATG_Batch.ps1

clear;

%% --- CONFIG --- %
cliPath     = "R:\ENG_Breuer_Shared\agehrke\MATLAB\active-turbulence-grid\src\Backend\ATG_CONTROLLER\x64\Debug\ATG_CONTROLLER.exe";

% Single-vane settings
singleVanes = 5:8;          % nodes to test 0:14 available, 0:7 vertical vanes, 8:14 horizontal vanes
singleRpms  = [60];        % RPMs to sweep
velDur      = 5;           % velocity run duration [s]
logDur      = 20;           % logging duration [s]
logPeriodMs = 20;           % logging period [ms]

% Group runs (not implemented in PowerShell example)
groupRuns   = {};           % can be added later
groupJoinChar = ',';        % "," or " "
echoCliCmds = true;         % echo commands to console
%% ---------------- %

exeDir = fileparts(cliPath);

%% --- Start CLI Process --- %
% Use Java's ProcessBuilder to mimic PowerShell stdin/stdout redirection.
pb = java.lang.ProcessBuilder(cliPath);
pb.directory(java.io.File(exeDir));
pb.redirectErrorStream(true);
proc = pb.start();

stdin  = proc.getOutputStream();
stdout = proc.getInputStream();
writer = java.io.OutputStreamWriter(stdin);
reader = java.io.BufferedReader(java.io.InputStreamReader(stdout));

% Prime stdout
if reader.ready()
    reader.readLine();
end

%% --- Helper function to send commands --- %
function sendCli(cmd, writer, echo)
    % Ensure cmd is a Java string
    jCmd = java.lang.String(char(cmd));

    if echo
        ts = datestr(now, 'HH:MM:SS.FFF');
        fprintf('[%s] ATG CLI << %s\n', ts, char(cmd));
    end

    % Write command + newline to the process input
    writer.write(jCmd);
    writer.write(java.lang.System.lineSeparator());
    writer.flush();
end


%% --- Run Single-Vane Sweeps --- %
disp("Running single-vane sweeps...");

for v = singleVanes
    for rpm = singleRpms
        % Start motion
        sendCli(sprintf("velrun %d rpm=%d dur=%d", v, rpm, velDur), writer, echoCliCmds);
        pause(1);

        % Start logging
        sendCli(sprintf("log %d period=%d dur=%d", v, logPeriodMs, logDur), writer, echoCliCmds);

        % Wait for logging to finish + buffer
        pause(logDur + 2);

        % Stop logger and node
        sendCli("stoplog", writer, echoCliCmds);
        sendCli(sprintf("stopnodes %d", v), writer, echoCliCmds);
        pause(1);
    end
end

%% --- Exit CLI --- %
sendCli("quit", writer, echoCliCmds);
pause(0.3);

if proc.isAlive()
    proc.destroy();
end

disp("All tests complete. CSVs should be beside: " + cliPath);
