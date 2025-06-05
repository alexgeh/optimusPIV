clear

BaudRate = 115200;
bnc = serialport('COM7', BaudRate);
bnc.configureTerminator('CR/LF');
bnc.Timeout = 1.0;

disp('Pulse generator connected.')
