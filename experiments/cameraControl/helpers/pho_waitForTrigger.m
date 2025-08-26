function pho_waitForTrigger(nDeviceNo, hardwareTrigger)
%% This function waits for a hardware trigger or gives the user the option
%  to trigger the cameras with a software trigger

PDC_DEV_VALUE(); % Load PDC variables

if hardwareTrigger
    disp("Waiting for camera hardware trigger.")
    while 1
        sub_GetStatus();
        if nStatus ~= PDC_STATUS_RECREADY
            break;
        end
    end
else
    disp("Waiting for camera software trigger. Briefly hold the button 'g' to do a software trigger.")
    while 1
        k = getkey(); % Wait for a key press
        if k == 'g'
            disp('Software trigger initiated.');
            pho_softwareTrigger(nDeviceNo);
            break;
        end
    end
end

end
