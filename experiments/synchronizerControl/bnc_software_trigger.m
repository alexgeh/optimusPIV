function bnc_software_trigger(bnc, delay)
    % BNC Software Trigger function
    % Triggers the BNC using a software command.

    if ~exist('delay','var')
        delay = 5;
    end

    disp("SOFTWARE TRIGGER LAUNCHING IN");
    for t = delay:-1:1
        fprintf(">>> %d <<<\n", t);
        pause(1);
    end

    query(bnc, "*TRG");
    disp("BNC Triggered via Software.");
end
