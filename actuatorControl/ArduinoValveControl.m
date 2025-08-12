%%MUST CHANGE
port = "COM3";
% port = "/dev/cu.usbmodem1301";
baud = 9600;


%Clear variables
disp("start test")
if exist("arduino", "var")
    clear arduino
end

% Connect to arduino
arduino = serialport(port, baud);


%must pause for some time
pause(2);                       % Allow Arduino to reboot
write(arduino, 1, "uint8");    % Send test byte
pause(5);
write(arduino, 0, "uint8")
pause(10)
write(arduino, 1, "uint8")

disp("test done")

% disp("start 1min on 10 min off cycle")
% %turns on for 1 minute after 10 minutes of off
% %press ctrl-C to exit infinite loop.
% while true
%     write (arduino, 1, "uint8")
%     pause(60)
%     write (arduino, 0, "uint8")
%     pause(600)
% end