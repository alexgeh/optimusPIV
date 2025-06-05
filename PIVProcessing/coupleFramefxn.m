sourceFolder = 'C:\Users\agehrke\Downloads\photronTestRec\cpp_test_script\4_IT_WORKS_recording_20250313_201647\S0001\';
destination = 'C:\Users\agehrke\Downloads\photronTestRec\cpp_test_script\4_IT_WORKS_recording_20250313_201647\S0001_renamed\';


coupleFrame(sourceFolder, destination)

%make a new directory with updated names
function coupleFrame(sourceFolder, destination)
    if ~isfolder(sourceFolder)
        error("Source folder does not exist. Double-check path: " + sourceFolder)
    end
    
    %makes the destination Folder
    if ~isfolder(destination)
        mkdir(destination)
    end

   doubleframecounter = 1;
   %grab the .tif files in sourceFolder
   imglist = dir(fullfile(sourceFolder, '*.tif'));
   
   %Check double frames (correct # of images)
    if mod(length(imglist),2) == 1 
        disp("Incomplete double frame present")
        %error("Incomplete double frame present")
    end

    %Print number of .tif frames
    disp("Total number of .tif files: " + num2str(length(imglist)));

    for i = 1:2:length(imglist)-1
        [~, name1, ext] = fileparts(imglist(i).name);
        [~, name2, ~] = fileparts(imglist(i+1).name);
        
        newName1 = ['Frame_', sprintf('%06d', doubleframecounter), '_0', ext];
        newName2 = ['Frame_', sprintf('%06d', doubleframecounter), '_1', ext];
        
        oldPath1 = fullfile(sourceFolder, imglist(i).name);
        oldPath2 = fullfile(sourceFolder, imglist(i+1).name);
        newPath1 = fullfile(destination, newName1);
        newPath2 = fullfile(destination, newName2);

        % Move and rename the files
        movefile(oldPath1, newPath1);
        movefile(oldPath2, newPath2);

        doubleframecounter = doubleframecounter + 1;
    end
    disp('Transfer complete')
end
 

    









         