%% Load all cases recorded before DFD into the data base
clear

% Where all optimizations are being stored:
rootDir = 'R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\';

% synchronous control - TI_target = 0.2, homogeneous, isotropic
meta.caseID = '20251017_ATG_bayes_opt_3';
meta.description = 'synchronous control - TI_target = 0.2, others: homogeneous, isotropic';
meta.weights = struct('J_TI',0.6,'J_hom_velgrad',0.01,'J_hom_TIgrad',0.01,'J_hom_CV',0.28,'J_aniso',0.1);
meta.xCropRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
meta.yCropRange = [-0.0650 0.1396];
meta.nProcFrames = 200; 
meta.TI_target = 0.2;
optDB = DB_addCase([], fullfile(rootDir, meta.caseID), meta);

% y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic
meta.caseID = '20251022_ATG_bayes_opt_4';
meta.description = 'NO CONVERGENCE, FAULTY FRAMES, WEIGHTS UNKNOWN: y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic';
meta.weights = struct('J_TI',0.6927,'J_hom_dUdy',0.089,'J_hom_TIgrad',0.14,'J_hom_CV',0.0437,'J_aniso',0.0346);
meta.xCropRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution, used for opt runs 4 to 7)
meta.yCropRange = [-0.111 0.137];
meta.nProcFrames = 190; 
meta.TI_target = 0.2;
meta.dudy_target = -2.5;
optDB = DB_addCase(optDB, fullfile(rootDir, meta.caseID), meta);

% y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic
meta.caseID = '20251023_ATG_bayes_opt_5';
meta.description = 'NO CONVERGENCE, POOR WEIGHTS SET, WEIGHTS UNKNOWN: y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic';
meta.weights = struct('J_TI',0.6927,'J_hom_dUdy',0.089,'J_hom_TIgrad',0.14,'J_hom_CV',0.0437,'J_aniso',0.0346);
meta.xCropRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution, used for opt runs 4 to 7)
meta.yCropRange = [-0.111 0.137];
meta.nProcFrames = 190; 
meta.TI_target = 0.2;
meta.dudy_target = -2.5;
optDB = DB_addCase(optDB, fullfile(rootDir, meta.caseID), meta);

% y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic
meta.caseID = '20251023_ATG_bayes_opt_6';
meta.description = 'y-gradient control - TI_target = 0.2, dudy_target = -2.5, others: homogeneous, isotropic';
meta.weights = struct('J_TI',0.6927,'J_hom_dUdy',0.089,'J_hom_TIgrad',0.14,'J_hom_CV',0.0437,'J_aniso',0.0346);
meta.xCropRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution, used for opt runs 4 to 7)
meta.yCropRange = [-0.111 0.137];
meta.nProcFrames = 190; 
meta.TI_target = 0.2;
meta.dudy_target = -2.5;
optDB = DB_addCase(optDB, fullfile(rootDir, meta.caseID), meta);

% y-gradient control - TI_target = 0.2, dTIdy_target = -0.2, others: homogeneous, isotropic
meta.caseID = '20251024_ATG_bayes_opt_7';
meta.description = 'y-gradient control - TI_target = 0.2, dTIdy_target = -0.2, others: homogeneous, isotropic';
meta.weights = struct('J_TI',0.6927,'J_hom_dUdy',0.089,'J_hom_TIgrad',0.14,'J_hom_CV',0.0437,'J_aniso',0.0346);
meta.xCropRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution, used for opt runs 4 to 7)
meta.yCropRange = [-0.111 0.137];
meta.nProcFrames = 190; 
meta.TI_target = 0.2;
meta.dTIdy_target = -0.2;
optDB = DB_addCase(optDB, fullfile(rootDir, meta.caseID), meta);

% Recompute everything, overwriting metrics but not saving big fields
optDBrecomp = DB_recompute(optDB, [], struct('force',true,'saveFields',true));

save('optDB.mat', 'optDB', '-v7.3');

return

%% Filter cases and extract data:
syncRun = DB_filterCases(optDB, 'meta.caseID', '20251017_ATG_bayes_opt_3');
freqHigh = DB_filterCases(optDB, 'actuation.freq', @(f) ~isempty(f) && f > 5);
runContains = DB_filterCases(optDB, 'meta.description', @(d) contains(d, 'y-gradient control'));

freqs = DB_extractData(syncRun, 'actuation.freq');   % numeric vector (NaNs for missing)
TI = DB_extractData(syncRun, 'metrics.TI_mean');     % numeric vector
ids = DB_extractData(syncRun, 'caseID');             % string array


ampgradALL = DB_extractData(optDB, 'actuation.ampgrad');




