function enabled = parse_enable_LDD_response(response, requestedState)
%PARSE_ENABLE_LDD_RESPONSE Parses LDD enable/disable response.
% Handles both WRITE ACK [02] and READ [03] response formats:
% [02][01][addr][0x10][ErrorCode][CS][CS]0x0D - WRITE ack
% [03][01][addr][0x10][State][CS][CS]0x0D - READ response

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

    D1 = bytes(5);  % Error code (if RW=2) or Enable state (if RW=3)
    enabled = false;  % Default fallback

    if RW == 2
        % --- WRITE ACKNOWLEDGMENT ---
        % D1 is the status/error code (0 = Success)
        if D1 == 0
            if nargin > 1
                if requestedState == 1
                    fprintf('Turning ON Diode... (Write Success)\n');
                    enabled = true;
                else
                    fprintf('Turning OFF Diode... (Write Success)\n');
                    enabled = false;
                end
            else
                fprintf('Diode write command SUCCESS (RW=0x02).\n');
            end
        else
            fprintf('Diode command FAILED with error code 0x%02X (RW=0x02).\n', D1);
        end
        
    elseif RW == 3
        % --- READ RESPONSE ---
        % D1 is the actual state (1 = Enabled, 0 = Disabled)
        if D1 == 1
            enabled = true;
            fprintf('Confirmed: Diode is ON [ENABLED] (RW=0x03).\n');
        elseif D1 == 0
            enabled = false;
            fprintf('Confirmed: Diode is OFF [DISABLED] (RW=0x03).\n');
        else
            error('Invalid enable state in read response: 0x%02X', D1);
        end
    end
end
