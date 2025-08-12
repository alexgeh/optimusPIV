%% Sample command to run DaVis in command line
%% C:\DaVis\win64\DaVis.exe "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\2D2C_PIV_SIDEBYSIDE.Hardware.lvs" "C:\Users\agehrke\OneDrive - Brown University\Documents\PIVBuffer\Project_FlowMaster_240212_171854\MS078_300_RPM.set"

%We have a very specific nesting structure. (see
% <C:\PIV_SANDBOX\20250731_test_run>;
% <C:\PIV_SANDBOX\20250731_test_run\proc_PIV>; 
% <C:\PIV_SANDBOX\20250731_test_run\proc_PIV\Processing_Parameters>
% and ALL NESTED FILES.
%
%   funkyStereo.OperationList.lvs --> directions for processing PIV (eg #
%   of passes or filters)
%
%   Properties.set; Properties.dir; Processing_parameters.set -->
%   experiment specific properties (eg camera settings or calibration data)
%
%   Processing_parameters.dir --> contains many files, most if whose
%   functions are unknown. DaVis know that this file contains the 'good
%   stuff' because of the NAME of the .set file in the same folder. This
%   should contain Camera1.cih(x) and Camera1.mraw, as well as
%   Camera2.cih(x) and Camera2.mraw. Camera2 files must be replaced in
%   order to process the data obtained by the automated loop trials.
%   Processing results will be found in a folder that looks something like 
%   PIV_SP(1x48x48_0%ov_ImgCorr) -- depending on what the specifications
%   from the .lvs file were. This data should then be moved to the folder
%   of form msXXXX.dir found in proc_PIV.dir.

davisExe = "C:\DaVis\win64\DaVis.exe";
lvsFile = 'C:\PIV_SANDBOX\20250731_test_run\proc_PIV\funkyStereo.OperationList.lvs'; %Contains directions for processing
setFile = 'C:\PIV_SANDBOX\20250731_test_run\proc_PIV\Processing_parameters.set'; %Contains information not unique to any specific trial; this is the information (ex # frames to process) that is grabbed for processing
command = davisExe + " -process " + lvsFile + " " + setFile;

disp("Processing: " + setFile)
[status, cmdout] = system(command);
disp("Processing complete for: \n" + setFile)
