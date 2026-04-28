function J = atgOpt_objFcn_synchr(freq, alpha, relBeta, config, hw)
%% Objective function for the active turbulence grid (ATG) flow field
%  optimization
%#ok<*GVMIS>

% Mutable states required for loop continuity
global lastSeedingTime
global recIdx
global optResults

plotting = config.OPT_settings.plotting;
theta_min = config.OPT_settings.theta_min;

elapsedTime = toc(lastSeedingTime) / 60;
if elapsedTime > 10 % Seeding every N minutes
    disp("next seeding interval starting in 5sec")
    pause(5)
    openSolenoidValve(hw.valveArduino);
    pause(30) % seeding time
    closeSolenoidValve(hw.valveArduino);
    lastSeedingTime = tic;
    pause(30) % circulation of particles
    disp("seeding complete, continuing with experiments")
end


%% Arm the system
bnc_arm(hw.bnc);
pause(0.5)


%% Ramp up laser:
targetHeads = 'both'; 
targetAmps  = 'max';

hw.laserControl.openShutter(targetHeads);
hw.laserControl.turnOnDiode(targetHeads);
hw.laserControl.setCurrent(targetAmps, targetHeads);


%% Trigger if using software mode
beta = alpha*relBeta; % Ensures always alpha >= beta
offset = -(90 - alpha - theta_min);
ampl = 180 - 2*theta_min - alpha - beta;

disp("ATG Run - freq: " + num2str(freq) + "; ampl: " + num2str(ampl) + "; offset: " + num2str(offset))

runAtgSync_optPIV(freq, ampl, offset, config, hw);

hw.laserControl.shutdown(targetHeads)
pause(0.5)


%% Transfer raw PIV to processing directory
waitForDownloadCycle(config.log_path, 60);
transfer_files(config.raw_PIV_dir, config.davis_templ_mraw, recIdx, "mraw");
pause(1)


%% Process PIV
processPIV(config.davis_exe, config.davis_lvs_file, config.davis_set_file);


%% Transfer processed PIV data to storage directory
transfer_files(config.davis_templ_dir, config.proc_PIV_dir, recIdx, "vc7");


%% Analyze PIV
PIVfolder = fullfile(config.proc_PIV_dir, sprintf('ms%04d', recIdx));

% Pass evaluation settings into the analyzer
[J, J_comp, metrics, fields] = objEval_turbulenceIntensity(PIVfolder, config.EVAL_settings);

disp("Current: J = " + num2str(J) + ...
    ", J_TI = " + num2str(J_comp.J_TI) + ...
    ", J_hom_velgrad = " + num2str(J_comp.J_hom_velgrad) + ...
    ", J_hom_TIgrad = " + num2str(J_comp.J_hom_TIgrad) + ...
    ", J_hom_CV = " + num2str(J_comp.J_hom_CV) + ...
    ", J_aniso = " + num2str(J_comp.J_aniso) + ...
    ", alpha = " + num2str(alpha) + ...
    ", relBeta = " + num2str(relBeta) + ", freq = " + num2str(freq) ...
    + ", ampl = " + num2str(ampl) + ", offset = " + num2str(offset))

optResults(recIdx).freq = freq; 
optResults(recIdx).alpha = alpha;
optResults(recIdx).relBeta = relBeta;
optResults(recIdx).ampl = ampl;
optResults(recIdx).offset = offset;
optResults(recIdx).J = J;
optResults(recIdx).J_comp = J_comp;
optResults(recIdx).metrics = metrics;
optResults(recIdx).fields = fields;

% --- NEW: Save step data immediately to disk ---
stepData = optResults(recIdx);
stepFileName = fullfile(config.analysis_PIV_dir, sprintf('optStep_ms%04d.mat', recIdx));
save(stepFileName, 'stepData');
disp("Saved step data to: " + stepFileName);
% ---------------------------------------------

recIdx = recIdx + 1;

end
