Photron Fastcam camera control script using Matlab

by Alexander Gehrke - 02/04/2025

Needs part of the PFV4(V4.3.0.0)_SDK included (NOT EVERYTHING - WILL LEAD TO FILE CONFLICTS)
  - PFV4(V4.3.0.0)_SDK\MATLAB\English\Demo_Module\64bit(x64)\Sample_R2010b_VS2005
  - PFV4(V4.3.0.0)_SDK\MATLAB\English\Demo_Module\64bit(x64)\MRAWFileSaveSample_R2010b_VS2005

# PARAMETER SETUP:
- Set IP of the camera to connect to 192.168.1.10 (Photron Fastcam 1) or 192.168.3.10 (Photron Fastcam 2)
in the wind tunnel.
- Specifiy frame rate, resolution, etc.

# CAMERA SETUP AND TRIGGER MODE:
- Set camera recording parameters
- Set camera in trigger mode

# VIDEO RECORDING
- Use hardware or software trigger to initiate recording

# VIDEO SAVING
- Download video to PC (MRAW) - !!! CURRENTLY CIHX FILE FUNCTION CRASHES MATLAB !!!
- 


SaveCihxFromCameraSample_R2010a_VS2005
SaveCihxFromCamera
sub_SaveCihxFromCamera
PDC_SaveCihxFromCamera.mex64

[nRet, nErrorCode] = PDC_SaveCihxFromCamera( handle, pPath, nDeviceNo, nChildNo, pRequired, pOptions, optionCount);
