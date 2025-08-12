function optimizePID()
% Connect to Galil
g = ConnectGalil('192.168.1.20');

% Initialize motor structure manually
encoderHigh = true;
m(1).n = 'B';

% Define PID parameter ranges
kp_vals = [50, 100, 150, 200];
ki_vals = [0.025, 0.05, 0.1];
kd_vals = [50, 100, 150, 200];


% Set experiment parameters
pitchA = 20;     % degrees
f = 1;           % Hz
np = 5;          % Number of cycles

best_rms = inf;
best_gains = struct();

for kp = kp_vals
    for ki = ki_vals
        for kd = kd_vals

            % Set gains
            m(1).KPhigh = kp;
            m(1).KIhigh = ki;
            m(1).KDhigh = kd;

            % Upload gains to controller
            setMotorPID(g, m(1), encoderHigh);

            % Run the motion
            [exp, m] = run_flap_motion(f, np, pitchA);

            % Calculate RMS tracking error
            exp_interp_x = interp1(exp(1).t, exp(1).x, m(1).t, 'linear', 'extrap');
            error = m(1).x - exp_interp_x;




            rms_err = sqrt(mean(error.^2));

            % Optional: Plot current performance
            figure(1); clf;
            plot(m(1).t, m(1).x, 'k--', exp(1).t, exp(1).x, 'b-');
            legend('Ideal','Recorded');
            title(sprintf('Kp=%.2f, Ki=%.3f, Kd=%.2f → RMS = %.4f', kp, ki, kd, rms_err));
            xlabel('Time [s]');
            ylabel('Position [deg]');
            drawnow;

            fprintf("Trying Kp=%.2f, Ki=%.3f, Kd=%.2f → RMS Error: %.4f\n", ...
                kp, ki, kd, rms_err);

            if rms_err < best_rms
                best_rms = rms_err;
                best_gains = struct('Kp', kp, 'Ki', ki, 'Kd', kd);
            end
        end
    end
end

fprintf("\nBest Gains Found:\nKp = %.2f\nKi = %.3f\nKd = %.2f\nRMS Error = %.4f\n", ...
    best_gains.Kp, best_gains.Ki, best_gains.Kd, best_rms);
end
