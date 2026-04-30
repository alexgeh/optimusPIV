function diag = diagnoseUncertaintyContributions(models, input_defs, output_defs, nCand)

    if nargin < 4
        nCand = 5000;
    end

    nInputs  = numel(input_defs);
    nOutputs = numel(output_defs);

    % Random candidate points in physical/design space
    Xcand = NaN(nCand, nInputs);

    for k = 1:nInputs
        bounds = input_defs(k).range;
        Xcand(:,k) = bounds(1) + rand(nCand,1) .* (bounds(2) - bounds(1));
    end

    sigmaRaw  = NaN(nCand, nOutputs);
    sigmaNorm = NaN(nCand, nOutputs);

    for m = 1:nOutputs
        [~, sd] = predict(models{m}, Xcand);

        sigmaRaw(:,m) = sd;

        if isfield(output_defs(m), 'scale') && ~isempty(output_defs(m).scale) && isfinite(output_defs(m).scale) && output_defs(m).scale > 0
            yScale = output_defs(m).scale;
        else
            yScale = 1;
        end

        if isfield(output_defs(m), 'exploreWeight') && ~isempty(output_defs(m).exploreWeight)
            w = output_defs(m).exploreWeight;
        else
            w = 1;
        end

        sigmaNorm(:,m) = w .* sd ./ yScale;
    end

    % Total exploration score, RMS-style
    exploreScore = sqrt(mean(sigmaNorm.^2, 2, 'omitnan'));

    % Fractional contribution of each output to squared score
    contrib = sigmaNorm.^2 ./ sum(sigmaNorm.^2, 2, 'omitnan');

    meanContrib = mean(contrib, 1, 'omitnan');
    maxContrib  = max(contrib, [], 1);

    [~, bestIdx] = max(exploreScore);

    diag = struct();
    diag.Xcand = Xcand;
    diag.sigmaRaw = sigmaRaw;
    diag.sigmaNorm = sigmaNorm;
    diag.exploreScore = exploreScore;
    diag.contrib = contrib;
    diag.meanContrib = meanContrib;
    diag.maxContrib = maxContrib;
    diag.bestIdx = bestIdx;
    diag.bestX = Xcand(bestIdx,:);
    diag.bestContrib = contrib(bestIdx,:);

    outputNames = {output_defs.name};

    fprintf('\nMean uncertainty contribution across candidate space:\n');
    disp(array2table(meanContrib, 'VariableNames', outputNames));

    fprintf('\nUncertainty contribution at most exploratory candidate:\n');
    disp(array2table(diag.bestContrib, 'VariableNames', outputNames));

    figure('Name','Exploration uncertainty contribution');
    bar(meanContrib);
    set(gca, 'XTickLabel', outputNames, 'XTickLabelRotation', 45);
    ylabel('Mean fractional contribution');
    title('Mean contribution to exploration uncertainty');
    grid on;

    figure('Name','Contribution at selected exploratory point');
    bar(diag.bestContrib);
    set(gca, 'XTickLabel', outputNames, 'XTickLabelRotation', 45);
    ylabel('Fractional contribution');
    title('Uncertainty contribution at max-acquisition candidate');
    grid on;
end
