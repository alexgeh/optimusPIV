%% Photron camera control
%  Connect to Photron Fastcam.
%  Set camera recording parameters.
%  Record video data.
%  Download video in MRAW file format to hard-drive.
%  TODO: Save CIHX file to hard drive. (Is needed to load MRAW file.)
%
%  created by Alexander Gehrke (02/04/2025)

clear all


%% Set camera and recording parameters
% load('detectVars.mat') % highjacked parameter set (no longer required - 20241115)
cameraIP = '192.168.1.10'; % Replace with your camera's IP address
                           % 192.168.1.10 (Photron Fastcam 1)
                           % 192.168.3.10 (Photron Fastcam 2)
nRecFrames = 30; % DOES NOT WORK YET - Max number of frames to record
setFps = 120; % Recording frequency [Hz]
pathName = 'C:\Users\agehrke\Downloads\photronTestRec'; % Folder where video file is saved at
fileName = 'test_20250206_2.mraw'; % Name of the video file
waitTime = 0.1; % Pause between certain commands being send to the camera
hardwareTrigger = true; % [true/false] Toggle between hardware and software trigger


%% Initialize Photron camera control
% nDetectNo = uint32(ip2dec(cameraIP)); % Convert IP address to hexdec and uint32
nDetectNo = ip2dec(cameraIP); % Convert IP address to hexdec and uint32
nFps = uint32(setFps); % Convert frame rate address to uint32
PDC_DEV_VALUE() % Load parameter definitions (c++ header file)
nInterfaceCode = PDC_INTTYPE_G_ETHER;  % PDC_INTTYPE_G_ETHER for Gigabit Ethernet
nDetectNum = PDC_MAX_DEVICE;
nDetectParam = PDC_DETECT_NORMAL;

run_sub_Init_DetectOpen() % This detects the camera and initializes a connection
pause(waitTime)
run_sub_functions() % Get camera status and meta information (current frame rate, resolution, etc.)
sub_SetRecordRate()


%% Display live image
nFps = uint32(setFps);
sub_SetRecordRate();
sub_GetLiveImage();
sub_DispImage();


%% Set recording
% pho_SetNFramesRec()
sub_SetRecordRate();
pause(waitTime)
sub_SetRecReady(); % Sets camera in trigger mode
pho_waitForTrigger(nDeviceNo, hardwareTrigger);
pause(0.2) % Effectively recording time in this test
pho_stopRecording(nDeviceNo);


%% Save mraw file to disk
pho_saveMRAW(nDeviceNo, nChildNo, fullfile(pathName, fileName))

return


%% Save Cihx to disk tests - WILL CRASH MATLAB
% The problem is that sub_SaveCihxFromCamera & PDC_SaveCihxFromCamera.mexw64
% are somehow bugged on the c++ level. They won't through an error, but
% straight up crash Matlab.

PDC_CIHX_VALUE();
sub_InitCihxSave()
SaveCihxFromCamera(nDeviceNo) % WILL CRASH MATLAB

