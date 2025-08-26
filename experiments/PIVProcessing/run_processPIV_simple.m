%% Sample command to run DaVis in command line
%% C:\DaVis\win64\DaVis.exe -process "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\2D2C_PIV_SIDEBYSIDE.Hardware.lvs" "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\Project_FlowMaster_240212_171854\MS078_300_RPM.set"

davisExe = "C:\DaVis\win64\DaVis.exe -process";
% lvsFile = "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\2D2C_PIV_SIDEBYSIDE.Hardware.lvs";
% setFile = "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\Project_FlowMaster_240212_171854\MS078_300_RPM.set";
lvsFile = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\optimusPIV_1\wTurbineTestProc_short.OperationList.lvs";
setFile = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\optimusPIV_1\turbine_large_FOV_2.set";
command = davisExe + " " + lvsFile + " " + setFile;

status = system(command);
