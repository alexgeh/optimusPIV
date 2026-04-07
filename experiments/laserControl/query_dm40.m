function response = query_dm40(laser, addr, cmdCode, dataByte)
%QUERY_DM40 Sends a read or write command depending on dataByte presence.
% If dataByte is provided, sends a WRITE command.
% Otherwise, sends a READ command.
% Returns raw HEXASC response from the device.

    if nargin < 4
        % Read
        cmdStr = build_command(addr, cmdCode);
    else
        % Write
        cmdStr = build_command(addr, cmdCode, dataByte);
    end

    writeline(laser, cmdStr);
    pause(0.1);  % adjust as needed

    response = readline(laser);
end

