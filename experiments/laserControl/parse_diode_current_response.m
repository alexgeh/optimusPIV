function amps = parse_diode_current_response(response)
%PARSE_DIODE_CURRENT_RESPONSE Extracts current in Amps from a HEXASC response

    % Each byte is 2 hex chars
    bytes = hex2dec(reshape(response, 2, []).');

    % Validate RW code (should be 0x03)
    if bytes(1) ~= 3
        error('Invalid response: expected RW code 0x03, got 0x%02X', bytes(1));
    end

    % Number of data bytes
    N = bytes(2);
    if N ~= 2
        error('Unexpected number of data bytes: %d', N);
    end

    % Diode current is D#1 and D#2
    current_raw = bitor(bitshift(bytes(5), 8), bytes(6));
    amps = current_raw / 100;  % 0.01 A units
end
