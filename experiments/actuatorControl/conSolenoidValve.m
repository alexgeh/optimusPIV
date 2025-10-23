function arduino = conSolenoidValve(channel)
%CONSOLENOIDVALVE Summary of this function goes here
%   Detailed explanation goes here
port = "COM"+num2str(channel);
% port = "/dev/cu.usbmodem1301";
baud = 9600;

%Clear variables
% disp("start test")
% if exist("arduino", "var")
%     clear arduino
% end

% Connect to arduino
arduino = serialport(port, baud);
end

