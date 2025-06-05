function bnc = bnc_init(comPort)
    % BNC Initialization function
    % Connects to BNC Model 577 and sets up general parameters.
    
    if nargin < 1
        comPort = "COM7"; % Default COM port, adjust if needed
    end

    % Establish connection
    bnc = serialport(comPort, 115200);
    configureTerminator(bnc, 'CR/LF');

    % Reset BNC settings (optional)
    % query(bnc, "*RST");
    % pause(2.0);

    % Set burst mode
    query(bnc, ":SPULSE:MODE BURST");
    pause(0.1);

    disp("BNC Initialized and Ready.");
end
