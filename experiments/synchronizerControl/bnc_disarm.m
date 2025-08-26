function bnc_disarm(bnc)
    % BNC Disarm function
    query(bnc, ":SPULSE:STATE OFF");
    disp("BNC Disarmed.");
end
