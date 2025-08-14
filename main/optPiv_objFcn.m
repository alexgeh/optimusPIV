function C_T = optPiv_objFcn(freq, pitchA)
%OPTPIV_OBJFCN Summary of this function goes here
%   Detailed explanation goes here

global triggerDelay
global bnc
global optPIV_settings
global recIdx
global optResults

g = optPIV_settings.g;
m = optPIV_settings.m;
np = optPIV_settings.np;
dt = optPIV_settings.dt;
RCN = optPIV_settings.RCN;
plotting = optPIV_settings.plotting;
config = optPIV_settings.config;
Uinf = optPIV_settings.Uinf;
rho_air = optPIV_settings.rho_air;
c = optPIV_settings.c;
R = optPIV_settings.R;


%% Arm the system
bnc_arm(bnc);
pause(0.5)


%% Trigger if using software mode
% if ~ext_trigger
%     bnc_software_trigger(bnc);
% end
triggerDelay = 5 / freq; % Skip first n cycles
[motorRec, motorStruct] = pitchingWingMotion(g, m, freq, pitchA, np, dt, RCN, plotting);


%% Transfer raw PIV to processing directory
waitForDownloadCycle(config.log_path, 60);
transfer_files(config.raw_PIV_dir, config.davis_templ_mraw, recIdx, "mraw");


%% Process PIV
processPIV(config.davis_exe, config.davis_lvs_file, config.davis_set_file);


%% Transfer processed PIV data to storage directory
transfer_files(config.davis_templ_dir, config.proc_PIV_dir, recIdx, "vc7");


%% Analyze PIV
VC7Folder = fullfile(config.proc_PIV_dir, sprintf('ms%04d', recIdx));
F_T = momentumDeficit(VC7Folder, Uinf, rho_air);
VTipMean = meanTipSpeed(c, deg2rad(pitchA), freq);
C_T = F_T./ (0.5 * rho_air * c * R * VTipMean.^2);
% C_T = F_T ./ (0.5 * rho_air * c * R * Uinf.^2)

disp("Current F_T = " + num2str(F_T) + ", Current C_T = " + num2str(C_T))

optResults(recIdx).motorRec = motorRec;
optResults(recIdx).C_T = C_T;
optResults(recIdx).F_T = F_T;
optResults(recIdx).VTipMean = VTipMean;

recIdx = recIdx + 1;

end

