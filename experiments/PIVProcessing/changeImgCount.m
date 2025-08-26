function success = changeImgCount(newValue, tagName, cameraXMLFile)

xmlText = fileread(cameraXMLFile); %read DaVis generated file as plaintext
pattern = ['<' tagName '>\s*\d+\s*</' tagName '>'];
replacement = ['<' tagName '>' num2str(newValue) '</' tagName '>'];

xmlText = regexprep(xmlText, pattern, replacement, 'once'); %Rewrite in file

fid = fopen(cameraXMLFile, 'w');
if fid == -1
    error('Failed to open file for writing: %s', cameraXMLFile);
end

fwrite(fid, xmlText); 
fclose(fid);
success = true;
end

%%
%changeImgCount
%Changes number of images within a data set that will be processed in a given batch
    %Inputs
        %newValue: the desired number of processed frames
        %tagName: the parameter to be modified -- here, it is 'ImageCount'
        %cameraXMLFile: the desired filepath (Camera1.xml). 
    %Output
        %success: bool indicating whether action was completed.
