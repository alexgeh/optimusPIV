function runAtg_modular(actuation, config, hw)
%% Run ATG actuation for one PIV optimization/active-learning iteration.
%
% Synchronous mode delegates to the existing, already-tested
% runAtgSync_optPIV function.
%
% Gradient mode uses the same config/hw structure and does not depend on the
% old globals used by atgOpt_objFcn_TIgrad/runAtgSync_optPIV_grad.

    if ~actuation.useGradActuation
        runAtgSync_optPIV(actuation.freq, actuation.ampl, actuation.offset, config, hw);
        return
    end

    %% Gradient ATG routine
    AtgExe = config.OPT_settings.AtgExe;
    outDir = config.OPT_settings.atgOutDir;

    allNodeIdx = config.OPT_settings.atgAllNodeIdx;

    maxRpm = config.OPT_settings.atgMaxRpm;
    maxRpmPerS = config.OPT_settings.atgMaxRpmPerS;
    homeRpm = config.OPT_settings.atgHomeRpm;
    homeRpmPerS = config.OPT_settings.atgHomeRpmPerS;

    shortCmdWait = config.OPT_settings.atgShortCmdWait_s;
    longCmdWait = config.OPT_settings.atgLongCmdWait_s;
    controlRate = config.OPT_settings.atgControlRate_ms; %#ok<NASGU>

    triggerDelay = config.OPT_settings.atgTriggerDelay_s;
    duration = config.OPT_settings.atgPostTriggerMotion_s + triggerDelay;

    disp('---------------------------------------------------')
    atg = ATGController(AtgExe, outDir);
    atg.connect();
    pause(longCmdWait)

    % Home grid
    atg.vel(homeRpm);
    pause(shortCmdWait)
    atg.acc(homeRpmPerS);
    pause(shortCmdWait)
    atg.gozero(allNodeIdx);
    pause(longCmdWait)

    % Increase motor speed and acceleration limits & run the grid
    atg.vel(maxRpm);
    pause(shortCmdWait)
    atg.acc(maxRpmPerS);
    pause(shortCmdWait)

    atg.bfsync_grad(allNodeIdx, actuation.ampl, actuation.freq, duration, ...
        actuation.offset, actuation.ampgrad, actuation.offsetgrad)

    pause(triggerDelay)
    bnc_software_trigger(hw.bnc, 0)
    pause(duration - triggerDelay + 5);

    % Home grid and sever connection. More robust this way as sometimes the
    % controller stops responding after long runs.
    atg.vel(homeRpm);
    pause(shortCmdWait)
    atg.acc(homeRpmPerS);
    pause(shortCmdWait)
    atg.gozero(allNodeIdx);
    pause(longCmdWait)

    clear atg  % Automatically calls delete() to shut down the CLI
    disp('---------------------------------------------------')
end
