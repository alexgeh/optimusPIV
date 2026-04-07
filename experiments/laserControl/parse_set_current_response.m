function amps = parse_set_current_response(response)
%PARSE_SET_CURRENT_RESPONSE Parses response to current set/read command.
% Accepts both WRITE (RW=0x02) and READ (RW=0x03) responses.
% Format: [RW][02][A#][0x11][D#1][D#2][CS][CS]0x0D

    % Convert from HEX ASCII to bytes
    bytes = hex2dec(reshape(char(response), 2, []).');

    RW = bytes(1);
    if RW ~= 2 && RW ~= 3
        error('Invalid response: expected RW code 0x02 or 0x03, got 0x%02X', RW);
    end

    if bytes(2) ~= 2
        error('Unexpected number of data bytes: %d', bytes(2));
    end

    if bytes(4) ~= hex2dec('11')
        error('Unexpected command code in response: 0x%02X', bytes(4));
    end

    % Combine D#1 and D#2 (big-endian) to get current in 0.01 A
    current_raw = bitor(bitshift(bytes(5), 8), bytes(6));
    amps = current_raw / 100;

    fprintf('LDD current set/read: %.2f A (RW=0x%02X).\n', amps, RW);
end
