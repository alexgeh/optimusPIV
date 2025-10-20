function J = atgOpt_objFcn(freq, alpha, relBeta)
%% Objective function for the active turbulence grid (ATG) flow field
%  optimization
%#ok<*GVMIS>

% non-linear objective penalty:
% if relBeta >= alpha
%     J = 1e6; % Large penalty if constraint is violated
%     return
% end

global bnc
global optPIV_settings
global recIdx
global optResults

plotting = optPIV_settings.plotting;
config = optPIV_settings.config;
theta_min = optPIV_settings.theta_min;
% rho_air = optPIV_settings.rho_air;


%% Arm the system
bnc_arm(bnc);
pause(0.5)


%% Trigger if using software mode
beta = alpha*relBeta; % Ensures always alpha >= beta
offset = -(90 - alpha - theta_min);
ampl = 180 - 2*theta_min - alpha - beta;

disp("ATG Run - freq: " + num2str(freq) + "; ampl: " + num2str(ampl) + "; offset: " + num2str(offset))
% disp("press button to continue")
% waitforbuttonpress(); % verify grid actuation is sound

runAtgSync_optPIV(freq, ampl, offset);


%% Transfer raw PIV to processing directory
waitForDownloadCycle(config.log_path, 60);
transfer_files(config.raw_PIV_dir, config.davis_templ_mraw, recIdx, "mraw");


%% Process PIV
processPIV(config.davis_exe, config.davis_lvs_file, config.davis_set_file);


%% Transfer processed PIV data to storage directory
transfer_files(config.davis_templ_dir, config.proc_PIV_dir, recIdx, "vc7");


%% Analyze PIV
PIVfolder = fullfile(config.proc_PIV_dir, sprintf('ms%04d', recIdx));
[J, J_comp, metrics, fields] = objEval_turbulenceIntensity(PIVfolder);

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
recIdx = recIdx + 1;

end

