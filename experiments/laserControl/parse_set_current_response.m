function amps = parse_set_current_response(response, requestedAmps)
%PARSE_SET_CURRENT_RESPONSE Parses response to current set/read command.
% Accepts both WRITE ACK (RW=0x02) and READ (RW=0x03) responses.
% WRITE format: [02][01][A#][0x11][ErrorCode][CS][CS]0x0D
% READ format:  [03][02][A#][0x11][D#1][D#2][CS][CS]0x0D

    % Convert from HEX ASCII to bytes
    bytes = hex2dec(reshape(char(response), 2, []).');

    RW = bytes(1);
    if RW ~= 2 && RW ~= 3
        error('Invalid response: expected RW code 0x02 or 0x03, got 0x%02X', RW);
    end

    % Confirm command code
    cmdCode = bytes(4);
    if cmdCode ~= hex2dec('11')
        error('Unexpected command code in response: 0x%02X', cmdCode);
    end

    amps = NaN; % Default fallback

    if RW == 2
        % --- WRITE ACKNOWLEDGMENT ---
        % Expect 1 data byte for Write Ack
        if bytes(2) ~= 1
            error('Unexpected number of data bytes for WRITE ACK: %d', bytes(2));
        end
        
        errorCode = bytes(5);
        if errorCode == 0
            if nargin > 1
                fprintf('Setting Diode Current to %.2f A... (Write Success)\n', requestedAmps);
                amps = requestedAmps;
            else
                fprintf('Set Current command SUCCESS (RW=0x02).\n');
            end
        else
            fprintf('Set Current command FAILED with error code 0x%02X (RW=0x02).\n', errorCode);
        end

    elseif RW == 3
        % --- READ RESPONSE ---
        % Expect 2 data bytes for Read response
        if bytes(2) ~= 2
            error('Unexpected number of data bytes for READ: %d', bytes(2));
        end

        % Combine D#1 and D#2 (big-endian) to get current in 0.01 A
        current_raw = bitor(bitshift(bytes(5), 8), bytes(6));
        amps = current_raw / 100;

        fprintf('Confirmed: LDD current is currently at %.2f A (RW=0x03).\n', amps);
    end
end
