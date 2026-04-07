function is_external = parse_PRF_source_response(response)
%PARSE_PRF_SOURCE_RESPONSE Parses PRF source response (read or write ack).
% Accepts both READ [03] and WRITE [02] responses.
% Format: [RW][01][addr][0x23][D#1][CS][CS]0x0D
% D#1: 0 = INTERNAL, 1 = EXTERNAL

    % Convert HEX ASCII to bytes
    bytes = hex2dec(reshape(char(response), 2, []).');

    RW = bytes(1);
    if RW ~= 2 && RW ~= 3
        error('Invalid response: expected RW code 0x02 or 0x03, got 0x%02X', RW);
    end

    if bytes(2) ~= 1
        error('Unexpected number of data bytes: %d', bytes(2));
    end

    if bytes(4) ~= hex2dec('23')
        error('Unexpected command code in response: 0x%02X', bytes(4));
    end

    D1 = bytes(5);
    if D1 == 0
        is_external = false;
        fprintf('PRF source is INTERNAL (RW=0x%02X).\n', RW);
    elseif D1 == 1
        is_external = true;
        fprintf('PRF source is EXTERNAL (RW=0x%02X).\n', RW);
    else
        error('Invalid PRF source byte: 0x%02X', D1);
    end
end
