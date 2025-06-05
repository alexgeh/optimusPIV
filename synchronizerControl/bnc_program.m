function bnc_program(bnc, acquisition_freq_Hz, delta_t_us, pulse_width_us, nDoubleFrames)
    % BNC Programming function
    % Configures BNC channels with the given experimental parameters.

    % Define hardware/setup parameters (constant for this setup)
    cmdWaitTime = 0.1;
    safety_factor = 3.0;
    trigger_pulse_width_us = 10;
    interframe_t_us = 1.944;
    % camera_delay_us = 1.8;
    camera_delay_us = 50;
    % camera_delay_us = camera_delay_us+5000;
    laser_delay_us = 0;

    % Convert microseconds to seconds
    delta_t_s = delta_t_us * 1e-6;
    pulse_width_s = pulse_width_us * 1e-6;
    interframe_t_s = interframe_t_us * 1e-6;
    camera_delay_s = camera_delay_us * 1e-6;
    laser_delay_s = laser_delay_us * 1e-6;
    trigger_pulse_width_s = trigger_pulse_width_us * 1e-6;

    % Calculate frame timing
    frame_period_s = 1 / acquisition_freq_Hz;
    laser_pulse2_time = frame_period_s / 2 - laser_delay_s + camera_delay_s;
    laser_pulse1_time = laser_pulse2_time - delta_t_s;
    laser_gate_time = laser_pulse1_time - (safety_factor - 1) * pulse_width_s / 2;
    laser_gate_duration_s = laser_pulse2_time + pulse_width_s + (safety_factor - 1) * pulse_width_s - laser_pulse1_time;

    % Set burst counter
    query(bnc, sprintf(":SPULSE:BCOUNTER %d", nDoubleFrames));
    pause(cmdWaitTime);

    % Configure channels
    for ch = 1:4
        query(bnc, sprintf(":PULSE%d:OUTPUT:MODE TTL", ch));
        pause(cmdWaitTime);
        query(bnc, sprintf(":PULSE%d:CMODE BURST", ch));
        pause(cmdWaitTime);
    end

    % Configure Camera Sync (Clock Output)
    query(bnc, sprintf(":SPULSE:PERIOD %f", frame_period_s));

    % Configure Laser Gate (Channel 1)
    query(bnc, sprintf(":PULSE1:WIDTH %e", laser_gate_duration_s));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE1:DELAY %e", laser_gate_time));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE1:BCOUNTER %d", nDoubleFrames));
    pause(cmdWaitTime);

    % Configure Laser Pulse 1 (Frame A, Channel 2)
    query(bnc, sprintf(":PULSE2:WIDTH %e", pulse_width_s));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE2:DELAY %e", laser_pulse1_time));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE2:BCOUNTER %d", nDoubleFrames));
    pause(cmdWaitTime);

    % Configure Laser Pulse 2 (Frame B, Channel 3)
    query(bnc, sprintf(":PULSE3:WIDTH %e", pulse_width_s));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE3:DELAY %e", laser_pulse2_time));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE3:BCOUNTER %d", nDoubleFrames));
    pause(cmdWaitTime);

    % Configure Camera Trigger (Channel 4)
    query(bnc, sprintf(":PULSE4:WIDTH %e", trigger_pulse_width_s));
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE4:DELAY %e", 0)); % Explicitly set to zero
    pause(cmdWaitTime);
    query(bnc, sprintf(":PULSE4:BCOUNTER %d", nDoubleFrames));
    pause(cmdWaitTime);

    disp("BNC Programmed Successfully.");
end
