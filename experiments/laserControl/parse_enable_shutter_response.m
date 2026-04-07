function enabled = parse_enable_shutter_response(response)
%PARSE_ENABLE_SHUTTER_RESPONSE Parses response from enable shutter command.
% Accepts response to either a WRITE or a READ:
% [02][01][A#1][04][D#1][CS][CS]0x0D - WRITE ack
% [03][01][A#1][04][D#1][CS][CS]0x0D - READ response

    % Each byte is 2 hex chars (HEXASCII)
    response = char(response);
    bytes = hex2dec(reshape(response, 2, []).');

    RW = bytes(1);
    if RW ~= 2 && RW ~= 3
        error('Invalid response: expected RW code 0x02 or 0x03, got 0x%02X', RW);
    end

    % Number of data bytes
    N = bytes(2);
    if N ~= 1
        error('Unexpected number of data bytes: %d', N);
    end

    cmdCode = bytes(4);
    if cmdCode ~= 4
        error('Unexpected command code in response: 0x%02X', cmdCode);
    end

    D1 = bytes(5);  % Enable state: 0 or 1

    if D1 == 1
        enabled = true;
        fprintf('Shutter ENABLED (RW=0x%02X).\n', RW);
    elseif D1 == 0
        enabled = false;
        fprintf('Shutter DISABLED (RW=0x%02X).\n', RW);
    else
        error('Invalid enable byte: 0x%02X', D1);
    end
end
