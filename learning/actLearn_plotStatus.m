function actLearn_plotStatus(X, Y, targets, iter)
    figure(101); clf;

    % TI Tracking
    subplot(3,1,1);
    plot(Y(:,1), 'k-o', 'LineWidth', 1, 'MarkerFaceColor', 'g'); hold on;
    yline(targets.TI, 'r--', 'Target TI');
    title(sprintf('Iter %d: Measured TI Convergence', iter));
    ylabel('TI Mean'); grid on;

    % Homogeneity Tracking
    subplot(3,1,2);
    plot(Y(:,2), 'b-s', 'DisplayName', 'CV_U'); hold on;
    plot(Y(:,3), 'm-d', 'DisplayName', 'CV_TI');
    title('Flow Homogeneity (Lower is Better)');
    ylabel('CV'); legend('Location','best'); grid on;

    % Sampling Map (Input Space Coverage)
    subplot(3,1,3);
    scatter(X(:,1), X(:,2), 40, Y(:,1), 'filled');
    xlabel('Amplitude'); ylabel('Offset');
    title('Exploration Map (Color = TI)');
    colorbar; grid on;

    drawnow;
end
