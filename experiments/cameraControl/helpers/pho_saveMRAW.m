function pho_saveMRAW(nDeviceNo, nChildNo, fname)
%% Save mraw file to disk

PDC_DEV_VALUE(); % Load PDC variables
[ret, frameInfo, errorCode] = PDC_GetMemFrameInfo(nDeviceNo, nChildNo);
if ret == PDC_FAILED
    error('PDC_GetMemFrameInfo Error : %d', errorCode);
end

[ret, errorCode] = PDC_MRAWFileSaveOpen(nDeviceNo, nChildNo, fname, PDC_MRAW_BITDEPTH_16, 0);
if ret == PDC_FAILED
    error('PDC_MRAWFileSaveOpen Error : %d', errorCode);
end

startNo        = frameInfo.m_nStart;
endNo          = frameInfo.m_nEnd;
recordedFrames = frameInfo.m_nRecordedFrames;

disp("Saving MRAW video to disk (" + num2str(recordedFrames) + " frames) - " + fname)
for i=1:recordedFrames
    frameNo = startNo + int32(i - 1);

    if frameNo < 0
        frameNo = endNo + abs(startNo) + frameNo + int32(1);
    end

    [ret, errorCode] = PDC_MRAWFileSave(nDeviceNo, nChildNo, frameNo);
    if ret == PDC_FAILED
        PDC_MRAWFileSaveClose(nDeviceNo, nChildNo);

        error('PDC_MRAWFileSave Error : %d', errorCode);
    end
end

[ret, errorCode] = PDC_MRAWFileSaveClose(nDeviceNo, nChildNo);
if ret == PDC_FAILED
    error('PDC_MRAWFileSaveClose Error : %d', errorCode);
end

end
