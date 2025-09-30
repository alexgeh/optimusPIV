[nRet, nErrorCode] = PDC_SetStatus( nDeviceNo, nMode );

if nRet == PDC_FAILED
    disp(['PDC_SetStatus Error : ' num2str(nErrorCode)]);
end