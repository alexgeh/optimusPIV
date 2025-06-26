%% Sample command to run DaVis in command line
%% C:\DaVis\win64\DaVis.exe "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\2D2C_PIV_SIDEBYSIDE.Hardware.lvs" "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\Project_FlowMaster_240212_171854\MS078_300_RPM.set"

davisExe = "C:\DaVis\win64\DaVis.exe";
lvsFile = "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\2D2C_PIV_SIDEBYSIDE.Hardware.lvs";
setFile = "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\Project_FlowMaster_240212_171854\MS078_300_RPM.set";
command = davisExe + " " + lvsFile + " " + setFile;

status = system(command);
