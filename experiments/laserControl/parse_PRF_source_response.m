function is_external = parse_PRF_source_response(response, requestedState)
%PARSE_PRF_SOURCE_RESPONSE Parses PRF source response (read or write ack).
% Accepts both READ [03] and WRITE [02] responses.
% Format: [RW][01][addr][0x23][D#1][CS][CS]0x0D

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
    is_external = false; % Default fallback

    if RW == 2
        % --- WRITE ACKNOWLEDGMENT ---
        % D1 is the status/error code (0 = Success)
        if D1 == 0
            if nargin > 1
                if requestedState == 1
                    fprintf('Setting PRF source to EXTERNAL... (Write Success)\n');
                    is_external = true;
                else
                    fprintf('Setting PRF source to INTERNAL... (Write Success)\n');
                    is_external = false;
                end
            else
                fprintf('PRF source write command SUCCESS (RW=0x02).\n');
            end
        else
            fprintf('PRF source command FAILED with error code 0x%02X (RW=0x02).\n', D1);
        end
        
    elseif RW == 3
        % --- READ RESPONSE ---
        % D1 is the actual state (0 = INTERNAL, 1 = EXTERNAL)
        if D1 == 0
            is_external = false;
            fprintf('Confirmed: PRF source is INTERNAL (RW=0x03).\n');
        elseif D1 == 1
            is_external = true;
            fprintf('Confirmed: PRF source is EXTERNAL (RW=0x03).\n');
        else
            error('Invalid PRF source byte: 0x%02X', D1);
        end
    end
end
