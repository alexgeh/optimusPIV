function bnc_software_trigger(bnc)
    % BNC Software Trigger function
    % Triggers the BNC using a software command.

    disp("SOFTWARE TRIGGER LAUNCHING IN");
    for t = 5:-1:1
        fprintf(">>> %d <<<\n", t);
        pause(1);
    end

    query(bnc, "*TRG");
    disp("BNC Triggered via Software.");
end
