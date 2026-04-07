function enabled = parse_enable_LDD_response(response)
%PARSE_ENABLE_LDD_RESPONSE Parses LDD enable/disable response.
% Handles both WRITE ACK [02] and READ [03] response formats:
% [RW][01][addr][0x10][D#1][CS][CS]0x0D

    % Convert HEX ASCII to decimal bytes
    bytes = hex2dec(reshape(char(response), 2, []).');

    RW = bytes(1);
    if RW ~= 2 && RW ~= 3
        error('Invalid response: expected RW code 0x02 or 0x03, got 0x%02X', RW);
    end

    % Confirm 1 data byte
    if bytes(2) ~= 1
        error('Unexpected number of data bytes: %d', bytes(2));
    end

    % Confirm command code
    if bytes(4) ~= hex2dec('10')
        error('Unexpected command code in response: 0x%02X', bytes(4));
    end

    % Parse enable flag
    D1 = bytes(5);
    if D1 == 1
        enabled = true;
        fprintf('LDD ENABLED (RW=0x%02X).\n', RW);
    elseif D1 == 0
        enabled = false;
        fprintf('LDD DISABLED (RW=0x%02X).\n', RW);
    else
        error('Invalid enable byte: 0x%02X', D1);
    end
end
