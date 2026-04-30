function actLearn_plotStatus(X_run, Y_run, history, input_defs, output_defs, AL_settings, iter)
%% Plot active-learning status for the current run only.
%
% X_run/Y_run should contain only values recorded after this script started.
% This avoids overcrowding when the GP is trained from a much larger optDB.

    if isempty(Y_run)
        return
    end

    nKeep = min(size(Y_run,1), AL_settings.plotWindow);
    rowIdx = (size(Y_run,1)-nKeep+1):size(Y_run,1);
    Xp = X_run(rowIdx,:);
    Yp = Y_run(rowIdx,:);

    outputNames = {output_defs.name};
    outputLabels = {output_defs.label};
    inputLabels = {input_defs.label};

    tiIdx = find(strcmp(outputNames, 'TI_mean'), 1, 'first');
    if isempty(tiIdx)
        tiIdx = 1;
    end

    figure(101); clf;

    %% 1) Main target/first metric tracking
    subplot(2,2,1);
    plot(rowIdx, Yp(:,tiIdx), 'k-o', 'LineWidth', 1, 'MarkerFaceColor', 'g'); hold on;
    if isfield(output_defs(tiIdx), 'target') && isfinite(output_defs(tiIdx).target)
        yline(output_defs(tiIdx).target, 'r--', 'Target');
    end
    title(sprintf('Current run, iter %d: %s', iter, outputLabels{tiIdx}));
    xlabel('Current-run sample');
    ylabel(outputLabels{tiIdx});
    grid on;

    %% 2) Other measured metrics
    subplot(2,2,2);
    hold on;
    otherIdx = setdiff(1:size(Yp,2), tiIdx, 'stable');
    if isempty(otherIdx)
        plot(rowIdx, Yp(:,tiIdx), '-o', 'DisplayName', outputLabels{tiIdx});
    else
        for k = otherIdx
            plot(rowIdx, Yp(:,k), '-o', 'DisplayName', outputLabels{k});
        end
    end
    title('Current-run output metrics');
    xlabel('Current-run sample');
    ylabel('Metric value');
    legend('Location','best');
    grid on;

    %% 3) Improvement/progress indicators
    subplot(2,2,3);
    hold on;
    hIdx = max(1, numel(history.iter)-nKeep+1):numel(history.iter);
    if ~isempty(hIdx)
        if any(isfinite(history.exploreScore(hIdx)))
            plot(history.iter(hIdx), history.exploreScore(hIdx), '-o', 'DisplayName', 'Predicted exploration score');
        end
        if any(isfinite(history.targetCostPred(hIdx)))
            plot(history.iter(hIdx), history.targetCostPred(hIdx), '-s', 'DisplayName', 'Predicted target cost');
        end
        if any(isfinite(history.targetCostMeasured(hIdx)))
            plot(history.iter(hIdx), history.targetCostMeasured(hIdx), '-d', 'DisplayName', 'Measured target score');
        end
    end
    title('Progress indicator');
    xlabel('Iteration');
    ylabel('Dimensionless score');
    legend('Location','best');
    grid on;

    %% 4) Sampling map in first two active dimensions
    subplot(2,2,4);
    if size(Xp,2) >= 2
        scatter(Xp(:,1), Xp(:,2), 45, Yp(:,tiIdx), 'filled');
        xlabel(inputLabels{1});
        ylabel(inputLabels{2});
        title(sprintf('Current-run sampling map (color = %s)', outputLabels{tiIdx}));
        colorbar;
        grid on;
    else
        scatter(Xp(:,1), Yp(:,tiIdx), 45, Yp(:,tiIdx), 'filled');
        xlabel(inputLabels{1});
        ylabel(outputLabels{tiIdx});
        title('Current-run sampling map');
        colorbar;
        grid on;
    end

    drawnow;
end
