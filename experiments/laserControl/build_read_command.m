function cmd = build_read_command(addr, cmdCode)
%BUILD_READ_COMMAND Constructs a DM40 read command in HEXASC format.
% addr and cmdCode should be integers (e.g., 0 and 18 for diode current).

    RW   = uint8(1);  % Read
    N    = uint8(0);  % No data bytes for read
    A    = uint8(addr);
    C    = uint8(cmdCode);

    % Byte array: [RW, N, A, C]
    payload = [RW, N, A, C];

    % Checksum: sum of payload, two bytes (big endian)
    checksum = sum(payload);
    cs_hi = bitshift(checksum, -8);     % upper byte
    cs_lo = bitand(checksum, 255);      % lower byte

    % Final frame: payload + checksum + CR
    frame = [payload, cs_hi, cs_lo, 13];

    % Convert to HEX ASCII characters (e.g. [01] -> '01')
    cmd = upper(join(string(dec2hex(frame, 2)), ""));
    cmd = char(cmd);  % convert to char array for serial write
end
