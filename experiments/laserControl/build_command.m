function cmd = build_command(addr, cmdCode, dataByte)
%BUILD_COMMAND Builds either a read or write command for DM40.
%   - Read:  [RW=01][N=00][addr][cmdCode][CS][CS]
%   - Write: [RW=00][N=01][addr][cmdCode][dataByte][CS][CS]
%   - All output in HEXASCII as a char vector

    if nargin < 3
    % Read command
        RW = uint8(1);
        N = uint8(0);
        payload = [RW, N, uint8(addr), uint8(cmdCode)];
    else
    % Write command
        RW = uint8(0);
        N = uint8(numel(dataByte));  % Number of data bytes
        payload = [RW, N, uint8(addr), uint8(cmdCode), uint8(dataByte(:)')];
    end

    % Compute checksum
    checksum = sum(payload);
    cs_hi = bitshift(checksum, -8);
    cs_lo = bitand(checksum, 255);

    frame = [payload, cs_hi, cs_lo];

    % Convert to HEX ASCII
    cmd = upper(join(string(dec2hex(frame, 2)), ""));
    cmd = char(cmd);
end
