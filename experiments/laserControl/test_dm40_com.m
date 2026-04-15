%% DM 40 test script
clear

% Replace with your actual COM port
laser = serialport("COM9", 115200, "DataBits", 8, "Parity", "none", "StopBits", 1, "Timeout", 5);
configureTerminator(laser, "CR");

pause(1);

%% laser 1 read current
addr = 0;
cmdCode = hex2dec('12');
response = query_dm40(laser, addr, cmdCode);
current_A = parse_diode_current_response(response);


%% Laser 1 - Open Shutter
addr = 0;
cmdCode = hex2dec('04');
dataByte = 0;  % 1 = open, 0 = close

% Send write command 
response = query_dm40(laser, addr, cmdCode, dataByte);
% Pass dataByte so the parser knows we are trying to Open
state = parse_enable_shutter_response(response, dataByte);  

pause(5); % wait 5 seconds for hardware to actuate

% Send read command 
response = query_dm40(laser, addr, cmdCode);
% No dataByte passed, so it knows it's purely reading the state
state = parse_enable_shutter_response(response);


%% Enable Diode

addr = 0;
cmdCode = hex2dec('10');
dataByte = 0;  % 1 = enable, 0 = disable

% Send write command 
response = query_dm40(laser, addr, cmdCode, dataByte);
% Pass dataByte so the parser knows what action we took
enabled = parse_enable_LDD_response(response, dataByte);

pause(5); % Wait for hardware

% Read actual state
response = query_dm40(laser, addr, cmdCode);
% No dataByte passed, parser defaults to READ logic
enabled = parse_enable_LDD_response(response);


%% Set Current

addr = 0;
cmdCode_set = hex2dec('11'); % 0x11 = SET current target
ampsToSet = 0;  % Your target current
rawCurrent = uint16(ampsToSet * 100);  

D1 = bitshift(rawCurrent, -8);  % high byte
D2 = bitand(rawCurrent, 255);   % low byte

% Send write command to 0x11
response = query_dm40(laser, addr, cmdCode_set, [D1, D2]);
amps = parse_set_current_response(response, ampsToSet);

pause(5); % Give the laser time to ramp up

% Read Actual Current
cmdCode_read = hex2dec('12'); % 0x12 = READ actual measured current

% Read response from 0x12
response = query_dm40(laser, addr, cmdCode_read);
current_A = parse_diode_current_response(response);


%% Set PRF Source

addr = 0;
cmdCode = hex2dec('23');
dataByte = 0;  % 1 = EXTERNAL, 0 = INTERNAL

% Send write command 
response = query_dm40(laser, addr, cmdCode, dataByte);
% Pass dataByte so the parser knows the intended action
is_external = parse_PRF_source_response(response, dataByte);

pause(1); % Brief pause for the controller to process

% Read actual state
response = query_dm40(laser, addr, cmdCode);
% Read response confirms the hardware state
is_external = parse_PRF_source_response(response);

