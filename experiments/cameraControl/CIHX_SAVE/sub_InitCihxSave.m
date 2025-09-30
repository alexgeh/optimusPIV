[nRet, pHandle, nErrorCode] = PDC_InitCihxSave;

if nRet == PDC_FAILED
    disp(['PDC_InitCihxSave Error : ' num2str(nErrorCode)]);
end