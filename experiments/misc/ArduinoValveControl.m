%%MUST CHANGE
port = "COM3";
baud = 9600;

seedingTime = 30;

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


%%
disp("open valve in 5sec")
pause(5);
disp("seeding for " + seedingTime)

write(arduino, 0, "uint8")
pause(seedingTime)
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