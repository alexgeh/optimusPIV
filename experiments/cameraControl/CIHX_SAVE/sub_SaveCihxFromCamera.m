[nRet, nErrorCode] = PDC_SaveCihxFromCamera( handle, pPath, nDeviceNo, nChildNo, pRequired, pOptions, optionCount);

if nRet == PDC_FAILED
    disp(['PDC_SaveCihxFromCamera Error : ' num2str(nErrorCode)]);
end

