function [models, stats] = actLearn_trainOutputModels(X, Y, output_defs, varargin)
% actLearn_trainOutputModels  Shared GP training routine for ATG active learning.
%
%   [models, stats] = actLearn_trainOutputModels(X, Y, output_defs)
%
% Use this function both in the active-learning experiment and in offline
% analysis so the reported diagnostics describe the same model class that is
% used to choose new actuation points.
%
% Inputs
%   X           n-by-d input matrix. Use the same scaling convention in the
%               experiment and analysis. Recommended: normalised [0,1].
%   Y           n-by-m output matrix.
%   output_defs struct array with fields used by the active learner, or a
%               cell/string array of output names for analysis-only use.
%
% Name-value options
%   'KernelFunction'   default: 'ardmatern52'
%   'Standardize'      default: true
%   'MinTrain'         default: max(3,d+1)
%   'DoLOO'            default: false
%
% Output
%   models(m).gp       fitted RegressionGP object
%   models(m).yScale   output scale used for normalized acquisition metrics
%   stats              model diagnostics, including optional LOO metrics

    p = inputParser;
    addParameter(p, 'KernelFunction', 'ardmatern52');
    addParameter(p, 'Standardize', true);
    addParameter(p, 'MinTrain', []);
    addParameter(p, 'DoLOO', false);
    parse(p, varargin{:});

    kernelFunction = p.Results.KernelFunction;
    standardize    = p.Results.Standardize;
    doLOO          = p.Results.DoLOO;

    nInputs = size(X,2);
    if isempty(p.Results.MinTrain)
        minTrain = max(3, nInputs + 1);
    else
        minTrain = p.Results.MinTrain;
    end

    output_defs = normaliseOutputDefs(output_defs);
    nOutputs = numel(output_defs);

    template = struct( ...
        'name', '', ...
        'label', '', ...
        'role', 'diagnostic', ...
        'target', NaN, ...
        'targetWeight', 0, ...
        'exploreWeight', 1, ...
        'yScale', NaN, ...
        'gp', [], ...
        'isTrained', false, ...
        'nTrain', 0, ...
        'kernelFunction', kernelFunction);

    models = repmat(template, 1, nOutputs);

    nValid       = NaN(nOutputs,1);
    yMean        = NaN(nOutputs,1);
    yStd         = NaN(nOutputs,1);
    yScale       = NaN(nOutputs,1);
    looRMSE      = NaN(nOutputs,1);
    looNRMSE     = NaN(nOutputs,1);
    looR2        = NaN(nOutputs,1);
    signalStd    = NaN(nOutputs,1);
    lengthScales = NaN(nOutputs, nInputs);

    for m = 1:nOutputs
        models(m).name          = output_defs(m).name;
        models(m).label         = output_defs(m).label;
        models(m).role          = output_defs(m).role;
        models(m).target        = output_defs(m).target;
        models(m).targetWeight  = output_defs(m).targetWeight;
        models(m).exploreWeight = output_defs(m).exploreWeight;

        y = Y(:,m);
        valid = all(isfinite(X),2) & isfinite(y);
        Xv = X(valid,:);
        yv = y(valid);

        nValid(m) = numel(yv);
        yMean(m)  = mean(yv, 'omitnan');
        yStd(m)   = std(yv, 'omitnan');

        s = yStd(m);
        if ~isfinite(s) || s <= 0
            s = max(abs(yMean(m)), 1);
        end
        yScale(m) = s;
        models(m).yScale = s;
        models(m).nTrain = nValid(m);

        if nValid(m) < minTrain
            warning('Not enough valid rows to train model for %s: %d valid rows.', output_defs(m).name, nValid(m));
            continue
        end

        gp = fitrgp(Xv, yv, ...
            'KernelFunction', kernelFunction, ...
            'Standardize', standardize);

        models(m).gp = gp;
        models(m).isTrained = true;

        [ell, sigF] = extractKernelInfo(gp, nInputs);
        lengthScales(m,:) = ell;
        signalStd(m) = sigF;

        if doLOO
            [looRMSE(m), looNRMSE(m), looR2(m)] = computeLOO(Xv, yv, kernelFunction, standardize, minTrain, s);
        end
    end

    stats = struct();
    stats.nValid = nValid;
    stats.yMean = yMean;
    stats.yStd = yStd;
    stats.yScale = yScale;
    stats.lengthScales = lengthScales;
    stats.signalStd = signalStd;
    stats.looRMSE = looRMSE;
    stats.looNRMSE = looNRMSE;
    stats.looR2 = looR2;
    stats.kernelFunction = kernelFunction;
    stats.inputDimension = nInputs;
    stats.outputNames = {output_defs.name};

    stats.summaryTable = table( ...
        string({output_defs.name})', nValid, yMean, yStd, yScale, looRMSE, looNRMSE, looR2, signalStd, ...
        'VariableNames', {'Output','N_valid','Mean','Std','YScale','LOO_RMSE','LOO_NRMSE','LOO_R2','SignalStd'});
end


function output_defs = normaliseOutputDefs(output_defs)
    if isstruct(output_defs)
        required = {'name','label','role','target','targetWeight','exploreWeight'};
        for m = 1:numel(output_defs)
            for r = 1:numel(required)
                f = required{r};
                if ~isfield(output_defs, f) || isempty(output_defs(m).(f))
                    switch f
                        case {'name','label'}
                            output_defs(m).(f) = '';
                        case 'role'
                            output_defs(m).(f) = 'diagnostic';
                        case 'target'
                            output_defs(m).(f) = NaN;
                        case 'targetWeight'
                            output_defs(m).(f) = 0;
                        case 'exploreWeight'
                            output_defs(m).(f) = 1;
                    end
                end
            end
            if isempty(output_defs(m).label)
                output_defs(m).label = output_defs(m).name;
            end
        end
        return
    end

    names = cellstr(output_defs);
    output_defs = struct('name',{},'label',{},'role',{},'target',{},'targetWeight',{},'exploreWeight',{});
    for m = 1:numel(names)
        output_defs(m).name = names{m}; %#ok<AGROW>
        output_defs(m).label = names{m};
        output_defs(m).role = 'diagnostic';
        output_defs(m).target = NaN;
        output_defs(m).targetWeight = 0;
        output_defs(m).exploreWeight = 1;
    end
end


function [ell, sigF] = extractKernelInfo(gp, nInputs)
    params = gp.KernelInformation.KernelParameters;

    if numel(params) >= nInputs + 1
        ell = params(1:nInputs)';
        sigF = params(nInputs + 1);
    elseif numel(params) >= 2
        % Isotropic kernel: repeat the single length scale for plotting.
        ell = repmat(params(1), 1, nInputs);
        sigF = params(2);
    elseif numel(params) == 1
        ell = repmat(params(1), 1, nInputs);
        sigF = NaN;
    else
        ell = NaN(1, nInputs);
        sigF = NaN;
    end
end


function [rmse, nrmse, r2] = computeLOO(X, y, kernelFunction, standardize, minTrain, yScale)
    n = numel(y);
    yPred = NaN(n,1);

    for i = 1:n
        train = true(n,1);
        train(i) = false;

        if sum(train) < minTrain
            continue
        end

        try
            mdl = fitrgp(X(train,:), y(train), ...
                'KernelFunction', kernelFunction, ...
                'Standardize', standardize);
            yPred(i) = predict(mdl, X(i,:));
        catch
            yPred(i) = NaN;
        end
    end

    err = yPred - y;
    rmse = sqrt(mean(err.^2, 'omitnan'));
    nrmse = rmse ./ max(yScale, eps);

    sse = sum((yPred - y).^2, 'omitnan');
    sst = sum((y - mean(y,'omitnan')).^2, 'omitnan');
    if sst > 0
        r2 = 1 - sse/sst;
    else
        r2 = NaN;
    end
end
