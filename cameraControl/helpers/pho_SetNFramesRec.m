
[ nRet, nTrgMode, nAFrames, nRFrames, nRCount, nErrorCode ] = PDC_GetTriggerMode( nDeviceNo );

if nRet == PDC_FAILED
    disp(['PDC_GetTriggerMode Error : ' num2str(nErrorCode)]);
end

[ nRet, nErrorCode ] = PDC_SetTriggerMode( nDeviceNo, nTrgMode, uint32(nRecFrames), nRFrames, nRCount );

if nRet == PDC_FAILED
    disp(['PDC_SetTriggerMode Error : ' num2str(nErrorCode)]);
end
