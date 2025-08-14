function [results, motorStruct] = pitchingWingMotion(galilObj, motorStruct, freq, pitchA, np, dt, RCN, plotting)
%% PITCHINGWINGMOTION Run a set of parameters on the pitching wing

flapSwitch = 1;
strokeOffset = 0; % Stroke motion zero position offset [deg] (22.5 for deformation measurements)

reset = false; % Reset position on limit switches
loadcell = false; % [true, false] Do you want to take loadcell data?

zerotime = 1; % Time for zero force measurements [s]
waittime = 1; % Pause time between operations (e.g. homing, zero-meas, etc)

% Create measurement parameter vector
para.np = np;
Tex = 1 ./ freq;
T = round(Tex/2,2)*2; % Round times to discretization precision
phase_shift = 0;
para.T = T;
% para.betaA = pitch_ampl;
para.beta0 = phase_shift;
freq = 1/T;
para.f = freq;
% fprintf('T = %i, pitch amp = %i, phase shift = %.1f\n', T, pitch_ampl, phase_shift)
texp = 0:dt:np*T; % Experiment time vector


%% Define motors and motions:
% Physical motion of pitching wing motor A
fp_A = freq; % Stroke frequency [Hz]
f_B = @(t) (pitchA*cos(2*pi*fp_A*t + strokeOffset)); % sinusoidal function

motorStruct(1).t = texp; % Physical time vector
motorStruct(1).x = f_B(motorStruct(1).t); % motion vector

% for mi = 1:length(m)
%     m(mi).x = addRamp(m(mi).x, m(mi).t, T, para.np);
% end
% m(2).x = m(2).x + strokeOffset + 0;

% m = m(1);


%% Preview desired motor trajectory
if plotting
    figure; plot(motorStruct(1).t, motorStruct(1).x - motorStruct(1).x(end)/2)

    % figure('Position',[207 100.5000 933.5000 488]);
    %
    % p1 = subplot(1,3,1);
    % plot(m(1).t, m(1).x); hold on
    % xlabel("t [sec]"), ylabel("motion [deg]")
    %
    % p2 = subplot(1,3,2);
    % plot(m(2).t, m(2).x); hold on
    % xlabel("t [sec]"), ylabel("motion [deg]")
    % p3 = subplot(1,3,3);
    % plot(m(3).t, m(3).x); hold on
    % xlabel("t [sec]"), ylabel("motion [deg]")
    % figure; plot(m(1).t, m(1).x)
end


%% Galil Setup
% g.command('DPB=0;');
% g.command('DPB=0; DPE=0; DPF=0;'); % Set current position as zero
galilObj.command(['SH' AllMotNam(motorStruct)]); % Turn on motors
pause(1e-3)
[motorStruct.RCN] = deal(RCN); % Set encoder recording frequency for all motors

% NI setup
if loadcell
    % Zero force recording:
    disp("Recording load cell bias.")
    NI.zeros = zeroforce(NI, 'time', zerotime);
    pause(waittime);
end

%% Homing procedure
disp("Move to start position")
pos = [motorStruct(1).x(1)];
simpleHome(galilObj, motorStruct, 'pos', pos, 'JGspeed', 10); % Go to specified position with a slow jog
pause(1e-3)


%% Start main motion:
% g.programDownloadFile('./helpers/trigger3DoF.dmc');
% pause(0.2)
% g.command('XQ#TRIGGER');

setMotorPID(galilObj, motorStruct(1), true); % FLAP

disp("Starting motion")
pause(2)
if loadcell
    results = Galil_motion(galilObj, motorStruct, NI); % Run with loadcell recording
else
    results = Galil_motion(galilObj, motorStruct); % Run without loadcell recording
end
% Stop motors and turn them off:
galilObj.command('ST');
pause(1)
setMotorPID(galilObj, motorStruct(1), false); % FLAP
% g.command('MO');


%% PLOT
if plotting
    % figure,
    hold on,
    % plot(motorStruct(1).t, motorStruct(1).x - motorStruct(1).x(1))

    plot(results(1).t, results(1).x - results(1).x(end)/2)
    legend('ideal','rec')

    xlim([texp(1), texp(end)])
end

end

