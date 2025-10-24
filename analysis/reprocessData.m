%% Reprocess PIV Optimization Data
clear

optID = 4;
projDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20251022_ATG_bayes_opt_4\";
pivFolder = fullfile(projDir, "proc_PIV");
variousColorMaps();


%% Load in old data and restructure:
load(fullfile(projDir, "workspaceOptimization.mat"))
nIter = length(optResults);

J = [optResults.J];
freq = [optResults.freq];
alpha = [optResults.alpha];
relBeta = [optResults.relBeta];
ampl = [optResults.ampl];
offset = [optResults.offset];

for iter = 1:nIter
    J_TI(iter) = optResults(iter).J_comp.J_TI; 
    if optID == 3
        J_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
    elseif optID == 4
        J_hom_dUdy(iter) = optResults(iter).J_comp.J_hom_dUdy;
    end
    J_hom_TIgrad(iter) = optResults(iter).J_comp.J_hom_TIgrad;
    J_hom_CV(iter) = optResults(iter).J_comp.J_hom_CV;
    J_aniso(iter) = optResults(iter).J_comp.J_aniso;
    
    TI_mean(iter) = optResults(iter).metrics.TI_mean;
    TI_std(iter) = optResults(iter).metrics.TI_std;
    TIgrad_mean(iter) = optResults(iter).metrics.TIgrad_mean;
    TIgrad_std(iter) = optResults(iter).metrics.TIgrad_std;
    CV(iter) = optResults(iter).metrics.CV;
    velgrad_mean(iter) = optResults(iter).metrics.velgrad_mean;
    aniso_mean(iter) = optResults(iter).metrics.aniso_mean;
end


%% Recompute coefficents with same function as optimization (without faulty frames)
for iter = 1:nIter
    folder = fullfile(pivFolder, sprintf('ms%.4d', iter));
    [re_J(iter), re_J_comp(iter), re_metrics(iter), re_fields(iter)] = objEval_turbulenceIntensity_TIgrad(folder);
end

%% === Unpack recomputed metrics and objective components ===
re_J_TI = zeros(1, nIter);
re_J_hom_velgrad = zeros(1, nIter);
% re_J_hom_dUdy = zeros(1, nIter);
re_J_hom_dTIdy = zeros(1, nIter);
re_J_hom_TIgrad = zeros(1, nIter);
re_J_hom_CV = zeros(1, nIter);
re_J_aniso = zeros(1, nIter);

re_TI_mean = zeros(1, nIter);
re_TI_std = zeros(1, nIter);
re_TIgrad_mean = zeros(1, nIter);
re_TIgrad_std = zeros(1, nIter);
re_CV = zeros(1, nIter);
re_velgrad_mean = zeros(1, nIter);
re_dTIdy_mean = zeros(1, nIter);
re_dudy_mean = zeros(1, nIter);
re_aniso_mean = zeros(1, nIter);

for iter = 1:nIter
    % --- Components of objective function
    re_J_TI(iter)         = re_J_comp(iter).J_TI;
    re_J_hom_velgrad(iter)= re_J_comp(iter).J_hom_velgrad;
%     re_J_hom_dUdy(iter)   = re_J_comp(iter).J_hom_dUdy;
    re_J_hom_dTIdy(iter)   = re_J_comp(iter).J_hom_dTIdy;
    re_J_hom_TIgrad(iter) = re_J_comp(iter).J_hom_TIgrad;
    re_J_hom_CV(iter)     = re_J_comp(iter).J_hom_CV;
    re_J_aniso(iter)      = re_J_comp(iter).J_aniso;

    % --- Flow field metrics
    re_TI_mean(iter)       = re_metrics(iter).TI_mean;
    re_TI_std(iter)        = re_metrics(iter).TI_std;
    re_TIgrad_mean(iter)   = re_metrics(iter).TIgrad_mean;
    re_TIgrad_std(iter)    = re_metrics(iter).TIgrad_std;
    re_dTIdy_mean(iter)    = re_metrics(iter).dTIdy_mean;
    re_CV(iter)            = re_metrics(iter).CV;
    re_velgrad_mean(iter)  = re_metrics(iter).velgrad_mean;
    re_dudy_mean(iter)     = re_metrics(iter).dudy_mean;
    re_aniso_mean(iter)    = re_metrics(iter).aniso_mean;
end


%% === Quick correlation and offset analysis ===
fields = {'J','J_TI','J_hom_dUdy','J_hom_TIgrad','J_hom_CV','J_aniso'};
fprintf('\n--- Correlation and mean offset between old and recomputed values ---\n')
for i = 1:numel(fields)
    old = eval(fields{i});
    new = eval(['re_' fields{i}]);
    r_lin = corr(old(:), new(:), 'rows','pairwise');
    r_rank = corr(old(:), new(:), 'Type','Spearman', 'rows','pairwise');
    shift = mean(new - old, 'omitnan');
    fprintf('%12s: rho_lin=%.3f, rho_rank=%.3f, meanΔ=%.3g\n', fields{i}, r_lin, r_rank, shift);
end


%% === Rank stability check ===
[~, oldRank] = sort(J);
[~, newRank] = sort(re_J);
rankDiff = abs(oldRank - newRank);
rho_rankJ = corr(J(:), re_J(:), 'Type','Spearman');
fprintf('\nMedian rank difference: %.1f (max %.1f), ρ_Spearman(J)=%.3f\n', ...
    median(rankDiff), max(rankDiff), rho_rankJ);


%% === Plot comparison between old and recomputed total J ===
figure('Name','J Comparison','Color','w');
subplot(1,2,1)
scatter(J, re_J, 50, 'filled')
xlabel('Original J'); ylabel('Recomputed J')
grid on; axis equal; refline(1,0)
title('Objective Comparison')

subplot(1,2,2)
plot(J - re_J, 'o-')
xlabel('Iteration'); ylabel('\DeltaJ (old - new)')
title('Per-iteration shift')
grid on


%% === Compare best trials before and after reprocessing ===
[~, bestOldIdx] = min(J);
[~, bestNewIdx] = min(re_J);

fprintf('\n--- Best trial comparison ---\n');
fprintf('Old best: #%d  f=%.3f  α=%.2f  β_rel=%.2f  A=%.2f°  θ=%.2f°  J=%.4f  TI=%.3f  dudy=%.3f\n', ...
    bestOldIdx, freq(bestOldIdx), alpha(bestOldIdx), relBeta(bestOldIdx), ...
    ampl(bestOldIdx), offset(bestOldIdx), J(bestOldIdx), TI_mean(bestOldIdx), dudy_mean(bestOldIdx));
fprintf('New best: #%d  f=%.3f  α=%.2f  β_rel=%.2f  A=%.2f°  θ=%.2f°  J=%.4f  TI=%.3f  dudy=%.3f\n', ...
    bestNewIdx, freq(bestNewIdx), alpha(bestNewIdx), relBeta(bestNewIdx), ...
    ampl(bestNewIdx), offset(bestNewIdx), re_J(bestNewIdx), re_TI_mean(bestNewIdx), re_dudy_mean(bestNewIdx));



%% Pareto / trade-off plots: TI vs homogeneity vs anisotropy
figure;
scatter(re_TI_mean, re_dudy_mean, 40);
colorbar; xlabel('TI\_mean'); ylabel('dudy\_mean');
title('TI vs dudy_mean (color=A)');
% mark target TI
xline(0.2,'r--','Target TI');

% also plot TI vs J_aniso
figure;
scatter(TI_mean, J_aniso, 40, A, 'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_aniso');
title('TI vs anisotropy (color=A)');
xline(0.2,'r--','Target TI');


%%
% M = [re_J_TI', re_J_hom_dUdy', re_J_hom_TIgrad', re_J_hom_CV', re_J_aniso'];
M = [re_J_TI', re_J_hom_velgrad', re_J_hom_dTIdy', re_J_hom_CV', re_J_aniso'];
% M: N x 5 raw metrics
lo = prctile(M,5,1);
hi = prctile(M,95,1);
% avoid zero-range
hi = max(hi, lo + eps);
Mclipped = min(max(M, lo), hi);
Mnorm = (Mclipped - lo) ./ (hi - lo);  % N x 5 in ~[0,1]

% Check median magnitudes
medNorm = median(Mnorm,1);

% Choose intuitive weights (example your proposal)
w_desired = [0.28, 0.34, 0.28, 0.05, 0.05];
w_emp = w_desired / sum(w_desired);  % normalized
% Test resulting contributions
contribs = Mnorm .* w_emp;           % per-trial weighted contributions
frac = contribs ./ (sum(contribs,2)+eps);
median_frac_weighted = median(frac,1);
disp('Median contribution fractions after percentile normalization:');
disp(median_frac_weighted);

%%
% Mnorm from Method 1 already computed
d = [0.28, 0.34, 0.28, 0.05, 0.05]; d = d / sum(d);

med = median(Mnorm,1); % typical magnitudes after normalization
w_suggest = d ./ (med + 1e-6);   % avoid division by zero
w_suggest = w_suggest / sum(w_suggest);
disp('Weights to achieve desired median contribution fractions:');
disp(w_suggest);
% Evaluate what these weights would do:
contribs2 = Mnorm .* w_suggest;
frac2 = contribs2 ./ (sum(contribs2,2)+eps);
disp('Resulting median fractions:'); disp(median(frac2,1));


