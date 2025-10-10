classdef ATGController < handle
    %ATGController  MATLAB interface for the Active Turbulence Grid CLI
    %
    %   Provides a structured interface to send commands and manage
    %   connection lifecycle automatically.
    %
    %   Example:
    %       atg = ATGController("C:\path\ATG_CONTROLLER.exe");
    %       atg.connect();
    %       atg.enableall();
    %       atg.bf([0,1], 30, 0.5, 10);
    %       atg.stopall();
    %       clear atg;  % automatically closes connection

    properties
        cliPath (1,1) string
        outDirectory (1,1) string = ""
        echo (1,1) logical = true
    end

    properties (Access = private)
        proc
        writer
        reader
        isConnected (1,1) logical = false
    end

    methods
        %% --- Constructor / Lifecycle -----------------------------------
        function obj = ATGController(cliPath, outDir)
            obj.cliPath = cliPath;
            if nargin > 1 && strlength(outDir) > 0
                obj.outDirectory = outDir;
            else
                obj.outDirectory = fileparts(cliPath);
            end
        end

        function connect(obj)
            if obj.isConnected, return; end
            exeDir = fileparts(obj.cliPath);
            pb = java.lang.ProcessBuilder(obj.cliPath);
            pb.directory(java.io.File(exeDir));
            pb.redirectErrorStream(true);
            obj.proc = pb.start();
            obj.writer = java.io.OutputStreamWriter(obj.proc.getOutputStream());
            obj.reader = java.io.BufferedReader(java.io.InputStreamReader(obj.proc.getInputStream()));
            pause(0.1);
            obj.isConnected = true;
            obj.echoMsg("Connected to CLI.");
        end

        function delete(obj)
            if obj.isConnected
                try
                    obj.send("quit");
                    pause(0.3);
                    if obj.proc.isAlive()
                        obj.proc.destroy();
                    end
                    obj.echoMsg("Connection closed.");
                catch ME
                    warning("ATG cleanup failed: %s", ME.message);
                end
            end
            obj.isConnected = false;
        end

        %% --- Generic send/read helpers --------------------------------
        function send(obj, cmd)
            if ~obj.isConnected
                error("ATGController:NotConnected", "Not connected. Call connect() first.");
            end
            jCmd = java.lang.String(char(cmd));
            if obj.echo
                ts = datestr(now, 'HH:MM:SS.FFF');
                fprintf('[%s] ATG CLI << %s\n', ts, char(cmd));
            end
            obj.writer.write(jCmd);
            obj.writer.write(java.lang.System.lineSeparator());
            obj.writer.flush();
        end

        function line = readline(obj)
            if obj.reader.ready()
                line = char(obj.reader.readLine());
                if obj.echo
                    fprintf('[ATG CLI >>] %s\n', line);
                end
            else
                line = '';
            end
        end

        function echoMsg(obj, msg)
            if obj.echo
                fprintf('[ATG] %s\n', msg);
            end
        end


        %% --- Core Command Wrappers ------------------------------------

        % --- Information / Utility
        function help(obj),          obj.send("help"); end
        function list(obj),          obj.send("list"); end
        function status(obj),        obj.send("status"); end

        % --- Node enable/disable
        function enableall(obj),     obj.send("enableall"); end
        function disableall(obj),    obj.send("disableall"); end

        % --- Homing
        function sethome(obj, nodes)
            obj.send(sprintf("sethome %s", obj.joinNodes(nodes)));
        end

        function capturehomes(obj, nodes)
            obj.send(sprintf("capturehomes %s", obj.joinNodes(nodes)));
        end

        function gohome(obj, nodes)
            obj.send(sprintf("gohome %s", obj.joinNodes(nodes)));
        end

        function gozero(obj, nodes)
            obj.send(sprintf("gozero %s", obj.joinNodes(nodes)));
        end

        % --- Motion
        function static(obj, nodes, deg, varargin)
            %STATIC  Move nodes by a specified angle (relative or absolute)
            %
            %   atg.static(nodes, deg)           -> relative move by deg
            %   atg.static(nodes, deg, 'abs')   -> move to absolute degree
            %
            %   Example:
            %       atg.static(0, 15);         % +15° relative
            %       atg.static([0 1], -10);    % -10° relative both
            %       atg.static(2, 45, 'abs');  % move node 2 to abs 45°

            absFlag = '';
            if nargin >= 4 && ischar(varargin{1}) && strcmpi(varargin{1}, 'abs')
                absFlag = ' abs';
            end
            cmd = sprintf("static %s %g%s", obj.joinNodes(nodes), deg, absFlag);
            obj.send(cmd);
        end

        function run(obj, nodes, type, varargin)
            %RUN Run motion pattern (sine, triangle, static)
            % Example: atg.run(0, 'sine', 'amp',20, 'freq',1)
            kv = obj.keyValueArgs(varargin);
            obj.send(sprintf("run %s %s %s", obj.joinNodes(nodes), type, kv));
        end

        function bf(obj, nodes, amp, freq, dur)
            if nargin < 5, dur = []; end
            if isempty(dur)
                cmd = sprintf("bf %s amp=%g freq=%g", obj.joinNodes(nodes), amp, freq);
            else
                cmd = sprintf("bf %s amp=%g freq=%g dur=%g", obj.joinNodes(nodes), amp, freq, dur);
            end
            obj.send(cmd);
        end

        function runrpm(obj, nodes, rpm, dur)
            if nargin < 4, cmd = sprintf("runrpm %s %g", obj.joinNodes(nodes), rpm);
            else, cmd = sprintf("runrpm %s %g %g", obj.joinNodes(nodes), rpm, dur);
            end
            obj.send(cmd);
        end

        function velrun(obj, nodes, rpm, dur)
            obj.send(sprintf("velrun %s rpm=%g dur=%g", obj.joinNodes(nodes), rpm, dur));
        end

        function stopnodes(obj, nodes)
            obj.send(sprintf("stopnodes %s", obj.joinNodes(nodes)));
        end

        function stopall(obj), obj.send("stopall"); end

        % --- Config
        function tick(obj, ms), obj.send(sprintf("tick %d", ms)); end
        function cpr(obj, counts), obj.send(sprintf("cpr %d", counts)); end
        function vel(obj, rpm), obj.send(sprintf("vel %g", rpm)); end
        function acc(obj, rpmPerS), obj.send(sprintf("acc %g", rpmPerS)); end

        function savemtr(obj, dir)
            if nargin < 2, obj.send("savemtr");
            else, obj.send(sprintf("savemtr %s", dir));
            end
        end

        function showencoder(obj), obj.send("showencoder"); end

        % --- Logging
        function log(obj, nodes, periodMs, dur, file)
            if nargin < 5 || strlength(file) == 0
                cmd = sprintf("log %s period=%d dur=%g", obj.joinNodes(nodes), periodMs, dur);
            else
                cmd = sprintf("log %s period=%d dur=%g file=%s", obj.joinNodes(nodes), periodMs, dur, file);
            end
            obj.send(cmd);
        end

        function stoplog(obj), obj.send("stoplog"); end

        % --- Exit / Quit
        function exit(obj), obj.send("exit"); end
    end

    %% --- Private helper methods ---------------------------------------
    methods (Access = private)
        function s = joinNodes(obj, nodes)
            if isnumeric(nodes)
                s = strjoin(string(nodes), ",");
            elseif isstring(nodes)
                s = strjoin(nodes, ",");
            else
                error("Invalid node format.");
            end
        end

        function s = keyValueArgs(~, args)
            if isempty(args), s = ""; return; end
            % Accept syntax like 'amp',30,'freq',1
            if mod(numel(args),2) ~= 0
                error("Key/value arguments must be pairs.");
            end
            parts = strings(1, numel(args)/2);
            for i = 1:2:numel(args)
                parts((i+1)/2) = sprintf("%s=%s", args{i}, num2str(args{i+1}));
            end
            s = strjoin(parts, " ");
        end
    end
end
