%% Script to analyze ATG PIV optimization sensitivity between input
%  parameters and objective function evalutions
%#ok<*SAGROW> 
clear

%% Data structure - Load and organize data
optID = 4;

switch optID
    case 3
        projDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20251017_ATG_bayes_opt_3\";
        plotDir = "R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\20251017_ATG_bayes_opt_3";
    case 4
        projDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20251022_ATG_bayes_opt_4\";
        plotDir = "R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\20251022_ATG_bayes_opt_4";
    otherwise
        error('opt ID not found')
end

pivFolder = fullfile(projDir, "proc_PIV");
load(fullfile(projDir, "workspaceOptimization.mat"))

variousColorMaps();

Jtot = [optResults.J]';
f = [optResults.freq]';
alpha = [optResults.alpha]';
relBeta = [optResults.relBeta]';
A = [optResults.ampl]';
theta = [optResults.offset]';

nIter = length(Jtot);

for iter = 1:nIter
    J_TI(iter) = optResults(iter).J_comp.J_TI;
    if optID == 3
        J_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
    elseif optID == 4
        J_hom_dUdy(iter) = optResults(iter).J_comp.J_hom_dUdy;
    end
    J_TIgrad(iter) = optResults(iter).J_comp.J_hom_TIgrad;
    J_CV(iter) = optResults(iter).J_comp.J_hom_CV;
    J_aniso(iter) = optResults(iter).J_comp.J_aniso;
    
    TI_mean(iter) = optResults(iter).metrics.TI_mean;
    TI_std(iter) = optResults(iter).metrics.TI_std;
    TIgrad_mean(iter) = optResults(iter).metrics.TIgrad_mean;
    TIgrad_std(iter) = optResults(iter).metrics.TIgrad_std;
    CV(iter) = optResults(iter).metrics.CV;
    velgrad_mean(iter) = optResults(iter).metrics.velgrad_mean;
    aniso_mean(iter) = optResults(iter).metrics.aniso_mean;
end

J_TI = J_TI'; 
if optID == 3
    J_velgrad = J_velgrad';
elseif optID == 4
    J_hom_dUdy = J_hom_dUdy';
end
J_TIgrad = J_TIgrad';
J_CV = J_CV';
J_aniso = J_aniso';

TI_mean = TI_mean';
TI_std = TI_std';
TIgrad_mean = TIgrad_mean';
TIgrad_std = TIgrad_std';
CV = CV';
velgrad_mean = velgrad_mean';
aniso_mean = aniso_mean';


%% best & worst
[bestJ,ibest] = min(Jtot);
[worstJ,iworst] = max(Jtot);

fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    ibest, f(ibest), A(ibest), theta(ibest), Jtot(ibest), TI_mean(ibest));
fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
    iworst, f(iworst), A(iworst), theta(iworst), Jtot(iworst), TI_mean(iworst));


%% correlations (params vs metrics)
X = [f, A, theta];
if optID == 3
    Y = [J_TI, J_velgrad, J_TIgrad, J_CV, J_aniso, Jtot, TI_mean];
elseif optID == 4
    Y = [J_TI, J_hom_dUdy, J_TIgrad, J_CV, J_aniso, Jtot, TI_mean];
end
paramNames = {'f','A','theta'};
metricNames = {'J_TI','J_velgrad','J_TIgrad','J_CV','J_aniso','Jtot','TI_mean'};

R = corr([X Y],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:3, 4:10); % adjust if different sizes
disp(array2table(Rpm,'RowNames',paramNames,'VariableNames',metricNames))

% scatter plots of A vs the main metrics
figure;
subplot(2,2,1); scatter(A, TI_mean, 20, 'filled'); xlabel('A (deg)'); ylabel('TI\_mean'); grid on
subplot(2,2,2); scatter(A, J_CV, 20, 'filled'); xlabel('A'); ylabel('J\_CV'); grid on
subplot(2,2,3); scatter(A, J_aniso, 20, 'filled'); xlabel('A'); ylabel('J\_aniso'); grid on
subplot(2,2,4); scatter(A, Jtot, 20, 'filled'); xlabel('A'); ylabel('J\_total'); grid on


%% linear regression (TI_mean ~ params)
T = table(f,A,theta,TI_mean);
lm = fitlm(T,'TI_mean ~ f + A + theta');
disp(lm);
% for J_CV
T2 = table(f,A,theta,J_CV);
lm2 = fitlm(T2,'J_CV ~ f + A + theta');
disp(lm2);


%% Pareto / trade-off plots: TI vs homogeneity vs anisotropy
figure;
scatter(TI_mean, J_CV, 40, A, 'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_CV');
title('TI vs CV (color=A)');
% mark target TI
xline(0.2,'r--','Target TI');
% also plot TI vs J_aniso
figure;
scatter(TI_mean, J_aniso, 40, A, 'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_aniso');
title('TI vs anisotropy (color=A)');
xline(0.2,'r--','Target TI');


%% 3D scatter (TI_mean vs J_CV vs J_aniso)
% f, A, theta: [N x 1] parameter vectors
% TI_mean, J_CV, J_aniso, Jtot : [N x 1] metric vectors
% idx_best = index of best run (you have it)
targetTI = 0.2;
tolTI = 0.02;        % +/- tolerance for "near-target"
CV_thresh = 0.2;     % user-chosen acceptable CV (tune)
aniso_thresh = 0.05; % acceptable anisotropy (tune)

% --- 3D scatter colored by amplitude A ---
figure('Name','3D trade space','Color','w','Position',[100 100 900 600]);
ax = axes;
scatter3(TI_mean, J_CV, J_aniso, 50, A, 'filled', 'MarkerEdgeColor',[.2 .2 .2]);
xlabel('TI\_mean'); ylabel('J\_CV'); zlabel('J\_aniso');
colormap(parula); cb = colorbar; ylabel(cb,'A (deg)');
grid on; view(45,20);
hold on;

% Highlight feasible region (TI near target & low CV & low aniso)
idx_feasible = (abs(TI_mean - targetTI) <= tolTI) & (J_CV <= CV_thresh) & (J_aniso <= aniso_thresh);
if any(idx_feasible)
    scatter3(TI_mean(idx_feasible), J_CV(idx_feasible), J_aniso(idx_feasible), ...
        120, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor','none', 'LineWidth',1.4);
end

% Mark best & worst
scatter3(TI_mean(ibest), J_CV(ibest), J_aniso(ibest), 160, 'p', ...
    'MarkerEdgeColor','k','MarkerFaceColor',[1 0 0],'LineWidth',1.5);
scatter3(TI_mean(iworst), J_CV(iworst), J_aniso(iworst), 160, 'x', ...
    'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0],'LineWidth',2);

title('TI\_mean vs J\_CV vs J\_aniso (color=A)');
hold off;

% --- 2D projection panels for clarity ---
figure('Name','Projections','Color','w','Position',[200 200 1000 300]);
subplot(1,3,1);
scatter(TI_mean,J_CV,50,A,'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_CV');
title('TI vs CV');

subplot(1,3,2);
scatter(TI_mean,J_aniso,50,A,'filled'); colorbar; xlabel('TI\_mean'); ylabel('J\_aniso');
title('TI vs anisotropy');

subplot(1,3,3);
scatter(J_CV,J_aniso,50,A,'filled'); colorbar; xlabel('J\_CV'); ylabel('J\_aniso');
title('CV vs anisotropy');

% --- Optional: label the interesting points (best, feasible few) ---
label_points = @(ix) arrayfun(@(i) text(TI_mean(i), J_CV(i), sprintf('  %d',i),'FontSize',9,'Color','k'), ix);
% label best and top few feasible
label_points(ibest);
feas_idx_list = find(idx_feasible);
if ~isempty(feas_idx_list)
    label_points(feas_idx_list(1:min(5,numel(feas_idx_list))));
end

% --- Save figures if desired ---
savePNG = false;
if savePNG
    saveas(gcf, 'projections.png');
    % For 3D scatter (first figure), you might want to capture it too:
    figure(1); set(gcf,'PaperPositionMode','auto'); print('trade3D.png','-dpng','-r300');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Further sensitivity analysis:

%% Deal with dependency alpha ↔ beta_rel → analyze in actuator space
% Example: partial correlation of J_CV with beta_rel controlling for alpha
[rho, pval] = partialcorr(relBeta, J_CV, alpha, 'Rows','complete');
fprintf('partial corr (J_CV vs beta_rel | alpha): rho=%.3f p=%.3g\n', rho, pval);
% partialcorr of J_CV vs theta controlling for A
[rho2, p2] = partialcorr(theta, J_CV, A, 'Rows','complete');
fprintf('partial corr (J_CV vs A): rho=%.3f p=%.3g\n', rho2, p2);

% regress out alpha from J_CV and from beta_rel
r1 = regress(J_CV, [ones(size(alpha)), alpha]); % only if using regress
% better: compute residuals directly with fitlm
mdl1 = fitlm(alpha, J_CV); res_Jcv = mdl1.Residuals.Raw;
mdl2 = fitlm(alpha, relBeta); res_b = mdl2.Residuals.Raw;
scatter(res_b, res_Jcv); xlabel('beta\_rel residual'); ylabel('J\_CV residual');
lsline; % shows partial trend


%% Compute per-trial contributions
wTI = 0.6;  % weight for target TI deviation
wH1 = 0.01;  % weight for velocity gradient homogeneity
wH2 = 0.01;  % weight for turbulence intensity homogeneity
wH3 = 0.28;  % weight for homogeneity of turbulence intensity coefficient of variation
wA  = 0.1;  % weight for anisotropy
%  assemble matrix of raw metric columns (use your actual metrics)
if optID == 3
    M = [J_TI, J_velgrad, J_TIgrad, J_CV, J_aniso]; % Nx5
elseif optID == 4
    M = [J_TI, J_hom_dUdy, J_TIgrad, J_CV, J_aniso]; % Nx5
end
w = [wTI, wH1, wH2, wH3, wA];                    % 1x5

% per-trial contributions
C = M .* reshape(w, 1, []);  % Nx5 elementwise
Csum = sum(C,2);
frac = C ./ (Csum + eps);    % Nx5 fractions

% summary: median fraction per metric
medFrac = median(frac,1);
fprintf('Median contribution fractions:\n');
disp(array2table(medFrac, 'VariableNames', {'J_TI','J_velgrad','J_TIgrad','J_CV','J_aniso'}));


%% Standardized effect sizes (regression with standardized variables)
% standardize variables
Zparams = ( [A, theta, f] - mean([A,theta,f]) ) ./ std([A,theta,f]);
ZJ = (J_TI - mean(J_TI))/std(J_TI);

lm = fitlm(Zparams, ZJ); disp(lm);
% repeat for other J components to see which param affects which component most


%% Partial R² (how much variance each metric explains in Jtot)
% regress Jtot on all metrics
tbl = array2table(M,'VariableNames',{'J_TI','J_velgrad','J_TIgrad','J_CV','J_aniso'});
tbl.Jtot = Jtot;
fullModel = fitlm(tbl,'Jtot ~ J_TI + J_velgrad + J_TIgrad + J_CV + J_aniso');
Rfull = fullModel.Rsquared.Ordinary;

% compute partial R2 for each term by drop-one
partialR2 = zeros(1,size(M,2));
for k=1:size(M,2)
    terms = tbl.Properties.VariableNames;
    keep = terms(~ismember(terms, terms(k)));
    formula = ['Jtot ~ ', strjoin(keep, ' + ')];
    modk = fitlm(tbl, formula);
    partialR2(k) = Rfull - modk.Rsquared.Ordinary;
end
disp(array2table(partialR2, 'VariableNames', tbl.Properties.VariableNames(1:end-1)))


%% Re-weighting suggestion (automatic, based on desired contribution proportions)
m_best = M(ibest,:); % 1x5 raw metrics at best
% wTI w_velgrad w_TIgrad w_CV wA:
% d = [0.6, 0.1, 0.05, 0.2, 0.05]; % example desired fractions
d = [0.4, 0.4, 0.1, 0.05, 0.05]; % example desired fractions
w_sugg = d ./ (m_best + eps);
w_sugg = w_sugg / sum(w_sugg); % normalize to sum 1 (optional)
disp('Suggested normalized weights:'); disp(w_sugg);

% More robust reweighting across larger parameter space (instead of single
% best point:
lo = prctile(M,5,1); hi = prctile(M,95,1);
% avoid zero-range
hi = max(hi, lo + eps);
Mnorm_all = (M - lo) ./ (hi - lo);
Mnorm_med = median(Mnorm_all,1); % typical scaled magnitude of each metric
% wTI w_velgrad w_TIgrad w_CV wA:
% d = [0.6, 0.1, 0.05, 0.2, 0.05]; % example desired fractions
d = [0.4, 0.4, 0.1, 0.05, 0.05]; % example desired fractions
w_sugg = d ./ (Mnorm_med + 1e-6);
w_sugg = w_sugg / sum(w_sugg);
disp(w_sugg);



%% Weight-sensitivity sweep
% coarse 2D sweep over w_TI vs w_CV, keep others equal small
w_grid = linspace(0,1,41);
sel_index = zeros(length(w_grid));
for i=1:length(w_grid)
    for j=1:length(w_grid)
        wTI_try = w_grid(i);
        wCV_try = w_grid(j);
        % keep remaining total weight as small constant or distribute
        w_remain = max(0, 1 - (wTI_try + wCV_try));
        w_try = [wTI_try, 0.01, 0.01, wCV_try, 0.01]; % example allocation
        Jtry = M * w_try';
        [~, sel_index(i,j)] = min(Jtry);
    end
end
imagesc(w_grid, w_grid, sel_index'); set(gca,'YDir','normal');
xlabel('w\_TI'); ylabel('w\_CV'); title('Selected best trial index for weight grid');
colorbar;


%% Dominance / Pareto check
P = pareto_bool([J_TI, J_CV, J_aniso]);
sum(P) % number of Pareto-efficient points

function isPareto = pareto_bool(objs)
% objs: N x K matrix (minimize each column)
N = size(objs,1);
isPareto = true(N,1);
for i=1:N
    for j=1:N
        if all(objs(j,:) <= objs(i,:)) && any(objs(j,:) < objs(i,:))
            isPareto(i) = false;
            break;
        end
    end
end
end
