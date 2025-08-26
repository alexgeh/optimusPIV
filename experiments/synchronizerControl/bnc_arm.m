function bnc_arm(bnc)
    % BNC Arm function
    % Arms the BNC and prepares it for triggering (external or software).

    % Set trigger mode
    query(bnc, ":SPULSE:TRIGGER:MODE TRIG");
    query(bnc, ":SPULSE:STATE ON");

    disp("BNC Armed - Ready for Trigger.");
end