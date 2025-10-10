classdef ATGController_simple < handle
    %ATGController  Object-oriented interface to the ATG CLI executable
    %
    %   Example:
    %       atg = ATGController("C:\path\to\ATG_CONTROLLER.exe");
    %       atg.connect();
    %       atg.velrun(0, 120, 10);
    %       atg.log(0, 20, 20);
    %       pause(25);
    %       atg.stoplog();
    %       atg.stopnodes(0);
    %       clear atg;  % cleans up automatically

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
        function obj = ATGController(cliPath, outDir)
            % Constructor: set paths only
            obj.cliPath = cliPath;
            if nargin > 1
                obj.outDirectory = outDir;
            else
                obj.outDirectory = fileparts(cliPath);
            end
        end

        function connect(obj)
            %CONNECT  Start the CLI process and open communication streams
            if obj.isConnected
                warning("ATGController already connected.");
                return;
            end

            exeDir = fileparts(obj.cliPath);
            pb = java.lang.ProcessBuilder(obj.cliPath);
            pb.directory(java.io.File(exeDir));
            pb.redirectErrorStream(true);
            obj.proc = pb.start();

            obj.writer = java.io.OutputStreamWriter(obj.proc.getOutputStream());
            obj.reader = java.io.BufferedReader( ...
                java.io.InputStreamReader(obj.proc.getInputStream()) );

            % Prime output
            if obj.reader.ready()
                obj.reader.readLine();
            end

            obj.isConnected = true;
            if obj.echo
                fprintf("[ATG] Connected to CLI: %s\n", obj.cliPath);
            end
        end

        function delete(obj)
            %DELETE  Ensure the CLI process is closed gracefully
            if obj.isConnected
                try
                    obj.send("quit");
                    pause(0.3);
                    if obj.proc.isAlive()
                        obj.proc.destroy();
                    end
                    if obj.echo
                        fprintf("[ATG] Connection closed.\n");
                    end
                catch ME
                    warning("Error during ATG cleanup: %s", ME.message);
                end
            end
            obj.isConnected = false;
        end

        function velrun(obj, node, rpm, dur)
            obj.send(sprintf("velrun %d rpm=%d dur=%g", node, rpm, dur));
        end

        function log(obj, node, periodMs, dur)
            % Add outDirectory if applicable
            if obj.outDirectory ~= ""
                logDir = sprintf("dir=%s", obj.outDirectory);
                obj.send(sprintf("log %d period=%d dur=%g %s", ...
                    node, periodMs, dur, logDir));
            else
                obj.send(sprintf("log %d period=%d dur=%g", ...
                    node, periodMs, dur));
            end
        end

        function stoplog(obj)
            obj.send("stoplog");
        end

        function stopnodes(obj, node)
            obj.send(sprintf("stopnodes %d", node));
        end

        function send(obj, cmd)
            %SEND  Low-level command write to CLI
            if ~obj.isConnected
                error("ATGController:NotConnected", "Controller not connected. Call connect() first.");
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
            %READLINE  (Optional) Read one line from CLI stdout
            if obj.reader.ready()
                line = char(obj.reader.readLine());
                if obj.echo
                    fprintf('[ATG CLI >>] %s\n', line);
                end
            else
                line = '';
            end
        end
    end
end

