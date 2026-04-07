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
dataByte = 0;  % 1 = enable, 0 = disable

% Send write command 
response = query_dm40(laser, addr, cmdCode, dataByte);
enabled = parse_enable_shutter_response(response);  % Accepts both 0x02 and 0x03


pause(5); %wait 5 seconds

% Send read command 
response = query_dm40(laser, addr, cmdCode);
enabled = parse_enable_shutter_response(response);  % Now should be RW=0x03


%% Enable Diode

addr = 0;
cmdCode = hex2dec('10');
dataByte = 0;  % 1 = enable, 0 = disable

% Send write command 
response = query_dm40(laser, addr, cmdCode, dataByte);
enabled = parse_enable_LDD_response(response);


pause(5);

% Read
response = query_dm40(laser, addr, cmdCode);
enabled = parse_enable_LDD_response(response);


%% Set Current

addr = 0;
cmdCode = hex2dec('11');
ampsToSet = 0.0;
rawCurrent = uint16(ampsToSet * 100);  

D1 = bitshift(rawCurrent, -8);  % high byte
D2 = bitand(rawCurrent, 255);   % low byte


response = query_dm40(laser, addr, cmdCode, [D1, D2]);
amps = parse_set_current_response(response);  % RW = 0x02


pause(5);


response = query_dm40(laser, addr, cmdCode);
amps = parse_diode_current_response(response);  % RW = 0x03


%% Set PRF source

addr = 0;
cmdCode = hex2dec('23');
dataByte = 0;  % 1 = EXTERNAL, 0 = INTERNAL

% Write
response = query_dm40(laser, addr, cmdCode, dataByte);
is_external = parse_PRF_source_response(response);  % RW = 0x02


pause(5);

% Read
response = query_dm40(laser, addr, cmdCode);
is_external = parse_PRF_source_response(response);  % RW = 0x03

%%