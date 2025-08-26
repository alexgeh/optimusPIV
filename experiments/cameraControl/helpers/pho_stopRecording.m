function pho_stopRecording(nDeviceNo)
%% Stop active recording of Photron camera

PDC_DEV_VALUE(); % Load PDC variables
[ret, errorCode] = PDC_SetStatus(nDeviceNo, PDC_STATUS_LIVE); % This stops the recording
if ret == PDC_FAILED
    error('PDC_SetStatus Error : %d', errorCode);
end
[ret, errorCode] = PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK);
if ret == PDC_FAILED
    error('PDC_SetStatus Error : %d', errorCode);
end
end
