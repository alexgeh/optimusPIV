%% Evaluate quality of parameter space exploration
clear

load("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20260429_ATG_highFreq_actLearn_4\actLearnDB.mat")

inputNames  = {'actuation.alpha', 'actuation.relBeta', ...
    'actuation.ampgrad', 'actuation.offsetgrad'}; 
outputNames = {'metrics.TI_mean', 'metrics.CV_U', 'metrics.CV_TI', ...
    'metrics.aniso_mean', 'metrics.dUdy_slope', 'metrics.dTIdy_slope'};
% out_names   = {'TI', 'CV_U', 'CV_TI', 'Anisotropy'}; % Friendly names for plots

inputRanges = [
    0, 59.5
    0, 1
   -45, 45
   -45, 45
];

fprintf('Extracting data from database...\n');
X_struct = DB_extractData(optDB, inputNames);
Y_struct = DB_extractData(optDB, outputNames);

X = [X_struct.actuation_alpha, X_struct.actuation_relBeta, ...
    X_struct.actuation_ampgrad, X_struct.actuation_offsetgrad];
Y = [Y_struct.metrics_TI_mean, Y_struct.metrics_CV_U, ...
         Y_struct.metrics_CV_TI, Y_struct.metrics_aniso_mean, ...
         Y_struct.metrics_dUdy_slope, Y_struct.metrics_dTIdy_slope];

% Normalise to [0,1]
Xn = NaN(size(X));
for k = 1:numel(inputNames)
    Xn(:,k) = (X(:,k) - inputRanges(k,1)) ./ diff(inputRanges(k,:));
end

disp(array2table([min(Xn); max(Xn); range(Xn)], ...
    'VariableNames', inputNames, ...
    'RowNames', {'min','max','range'}));

D = pdist(Xn);
fprintf('Minimum normalised pairwise distance: %.3f\n', min(D));
fprintf('Median normalised pairwise distance:  %.3f\n', median(D));
fprintf('Maximum normalised pairwise distance: %.3f\n', max(D));

%%
figure;
plotmatrix(Xn);
sgtitle('Normalised sampled input space');


%% min/max/range of outputs:
T = array2table([min(Y); max(Y); mean(Y); std(Y); range(Y)], ...
    'VariableNames', outputNames, ...
    'RowNames', {'min','max','mean','std','range'});
disp(T);


%% Compare GP model fitness
% normalised LOO RMSE < 0.3: surprisingly good
% 0.3–0.7: usable early trend
% 0.7–1.0: weak but not unexpected with few samples
% >1.0: GP is not yet predictive

for m = 1:numel(outputNames)
    y = Y(:,m);

    valid = all(isfinite(Xn),2) & isfinite(y);
    Xv = Xn(valid,:);
    yv = y(valid);

    n = numel(yv);
    yPred = NaN(n,1);
    yStd  = NaN(n,1);

    for i = 1:n
        train = true(n,1);
        train(i) = false;

        if sum(train) < 5
            continue
        end

        gpr = fitrgp(Xv(train,:), yv(train), ...
            'KernelFunction','ardsquaredexponential', ...
            'Standardize',true);

        [yPred(i), yStd(i)] = predict(gpr, Xv(i,:));
    end

    err = yPred - yv;
    rmse = sqrt(mean(err.^2,'omitnan'));
    yscale = std(yv,'omitnan');

    fprintf('\n%s\n', outputNames{m});
    fprintf('LOO RMSE: %.4g\n', rmse);
    fprintf('Output std: %.4g\n', yscale);
    fprintf('Normalised LOO RMSE: %.3f\n', rmse / max(yscale, eps));
end


%% GP length scales
for m = 1:numel(outputNames)
    y = Y(:,m);
    valid = all(isfinite(Xn),2) & isfinite(y);

    gpr = fitrgp(Xn(valid,:), y(valid), ...
        'KernelFunction','ardsquaredexponential', ...
        'Standardize',true);

    params = gpr.KernelInformation.KernelParameters;

    % For ARD squared exponential:
    % first d entries are length scales, last is signal std
    ell = params(1:size(Xn,2));

    fprintf('\n%s length scales:\n', outputNames{m});
    disp(array2table(ell(:)', 'VariableNames', inputNames));
end


%% Score (for target optimization)
J = [optDB.J];

figure;
plot(J, 'o-'); hold on;
plot(cummin(J), 'k-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Measured objective J');
legend('J','Best so far');
grid on;
title('Measured objective progress');


%% physical trends
for m = 1:numel(outputNames)
    figure;
    tiledlayout(2,2);

    for k = 1:numel(inputNames)
        nexttile;
        scatter(X(:,k), Y(:,m), 60, 'filled');
        xlabel(inputNames{k}, 'Interpreter','none');
        ylabel(outputNames{m}, 'Interpreter','none');
        grid on;
    end

    sgtitle(outputNames{m}, 'Interpreter','none');
end

%%