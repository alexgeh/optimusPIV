function recFlag = pho_checkRecording(nDeviceNo)
%% Check if Photrom camera is in recording mode
%
%  Output
%    true = camera is in recording mode
%    false = camera is not in recording mode

PDC_DEV_VALUE(); % Load PDC variables
sub_GetStatus();
% 2: Recording standby, 8: Recording in progress
if nStatus == PDC_STATUS_RECREADY || nStatus == PDC_STATUS_REC
    recFlag = true;
else
    recFlag = false;
end
end
