function processPIV(davisExe, lvsFile, setFile)
%% Process a case specified by the SET-file inside a davis project using
%  the processing instructions from the LVS-file
%
%  INPUT:
%  davisExe - location of the 'DaVis.exe'
%  lvsFile - Contains instructions for processing
%  setFile - Contains trial information
%
%  Author: Alexander Gehrke - 20250804

command = davisExe + " -process " + lvsFile + " " + setFile;
disp("Processing: " + setFile)
[status, cmdout] = system(command);
disp("Processing complete for: \n" + setFile)

end

