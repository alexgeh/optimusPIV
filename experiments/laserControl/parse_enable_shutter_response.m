function state = parse_enable_shutter_response(response, requestedState)
%PARSE_ENABLE_SHUTTER_RESPONSE Parses response from enable shutter command.
% Accepts response to either a WRITE or a READ:
% [02][01][A#1][04][ErrorCode][CS][CS]0x0D - WRITE ack
% [03][01][A#1][04][State][CS][CS]0x0D - READ response

    % Convert each byte from 2 hex chars (HEXASCII) to decimal
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

    D1 = bytes(5);  % Error code (if RW=2) or Enable state (if RW=3)
    state = false;  % Default fallback

    if RW == 2
        % --- WRITE ACKNOWLEDGMENT ---
        % D1 is the status/error code (0 = Success)
        if D1 == 0
            if nargin > 1
                if requestedState == 1
                    fprintf('Opening shutter... (Write Success)\n');
                    state = true;
                else
                    fprintf('Closing shutter... (Write Success)\n');
                    state = false;
                end
            else
                fprintf('Shutter write command SUCCESS (RW=0x02).\n');
            end
        else
            fprintf('Shutter command FAILED with error code 0x%02X (RW=0x02).\n', D1);
        end
        
    elseif RW == 3
        % --- READ RESPONSE ---
        % D1 is the actual state (1 = Enabled, 0 = Disabled)
        if D1 == 1
            state = true;
            fprintf('Confirmed: Shutter is OPEN [ENABLED] (RW=0x03).\n');
        elseif D1 == 0
            state = false;
            fprintf('Confirmed: Shutter is CLOSED [DISABLED] (RW=0x03).\n');
        else
            error('Invalid enable state in read response: 0x%02X', D1);
        end
    end
end
