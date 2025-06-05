function pho_softwareTrigger(nDeviceNo)
%% Trigger the camera from the software

PDC_DEV_VALUE(); % Load PDC variables
[ nRet, nErrorCode ] = PDC_TriggerIn( nDeviceNo ); % Software trigger
if nRet == PDC_FAILED
    disp(['PDC_TriggerIn Error : ' num2str(nErrorCode)]);
end
end
