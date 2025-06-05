%% Pulse generator control

%{
GD, 5/28/19
https://www.berkeleynucleonics.com/sites/default/files/577_user_manual_11-15-18.pdf
page 25 onwards
%}

clear


%% Connect to device and configure:
BaudRate = 115200;
bnc = serialport('COM7', BaudRate);
bnc.configureTerminator('CR/LF');
bnc.Timeout = 1.0;

disp('Pulse generator connected.')

% Connect to instrument object.
fopen(bnc);


%% Communicating with instrument object.
query(bnc, ':PULSE:STATE?')

query(bnc, ':PULSE:STATE ON')
pause(.5)
query(bnc, ':PULSE:STATE?')

query(bnc, ':PULSE:STATE OFF')
query(bnc, ':PULSE:STATE?')


%% Disconnect from instrument object.
delete(bnc);
