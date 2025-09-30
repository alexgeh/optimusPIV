function [ ] = save( nDeviceNo )

PDC_DEV_VALUE;
PDC_CIHX_VALUE;

% Set status
nMode = PDC_STATUS_PLAYBACK;
sub_SetStatus;

% Initialize CIHX function
sub_InitCihxSave
handle = pHandle;

% Set paramator
pPath = '.\\SaveCihxFromCamera.cihx'
nChildNo = 1;

pRequired.pFileFormat = 'Mraw';
pRequired.pColorType = PDC_CIH_COLORTYPE_COLOR_STR;
pRequired.colorDepth = 8;

pMetaOption0.pKey = PDC_CIH_KEY_FRAME_TOTAL;
pMetaOption0.pValue = '12';		

pMetaOption1.pKey = PDC_CIH_KEY_FRAME_START;
pMetaOption1.pValue = '-34';

pOptions.type = PDC_ARCHIVE_OPTION_TYPE_META;
pOptions.count = 2;
pOptions.option = [pMetaOption0 pMetaOption1];

optionCount = 1;

% Save
sub_SaveCihxFromCamera

% Get status
sub_GetCihxSaveStatus

% Finish
sub_ExitCihxSave

end

