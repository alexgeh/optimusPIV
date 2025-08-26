% Setup
laser = serialport("COM9", 115200, "DataBits", 8, "Parity", "none", "StopBits", 1, "Timeout", 1);

% Read current
resp = query_dm40(laser, 0, hex2dec('12'));  % 0x12 = read diode current
current_A = parse_diode_current_response(resp);

fprintf("Diode current: %.2f A\n", current_A);
