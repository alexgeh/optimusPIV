function response = query_dm40(laser, addr, cmdCode)
%QUERY_DM40 Sends a read command and reads the HEXASC response

    % Build the command
    cmdStr = build_read_command(addr, cmdCode);

    % Add CR (0x0D)
    cmdStr(end+1) = char(13);

    % Send
    write(laser, cmdStr, "string");

    % Read until carriage return
    raw = readline(laser);  % waits until CR (0x0D)
    response = raw;  % return as raw hex string
end
