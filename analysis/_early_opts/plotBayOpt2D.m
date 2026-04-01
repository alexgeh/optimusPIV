function plotBayOpt2D(X,Y)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    % Fit a GP model to the data
    gprMdl = fitrgp(X, Y, 'BasisFunction','none', ...
                          'KernelFunction','squaredexponential', ...
                          'Sigma',1e-3, ...   % noise term, adjust if needed
                          'Standardize',true);
    
    % Define a dense grid of X for plotting
    xGrid = linspace(min(X), max(X), 200)';
    
    % GP prediction
    [mu, sigma] = predict(gprMdl, xGrid);
    
    % 95% confidence intervals
    ciUpper = mu + 1.96*sigma;
    ciLower = mu - 1.96*sigma;
    
    % Shaded confidence region
    fill([xGrid; flipud(xGrid)], [ciUpper; flipud(ciLower)], ...
         [0.8 0.8 1], 'EdgeColor','none','FaceAlpha',0.3)
    
    % Mean prediction
    plot(xGrid, mu, 'b-', 'LineWidth', 2)
    
    % Sampled points
    scatter(X, Y, 50, 'k','filled')
    
    % Best observed point
    [bestY, idx] = min(Y);
    plot(X(idx), bestY, 'ro','MarkerSize',10,'LineWidth',2)
    
    xlabel('amplitude \theta_A [deg]')
    ylabel('-C_T')
    % title('Bayesian Optimization Surrogate Model')
    legend('95% CI','GP mean','Sampled points','Best observed')
    legend('Location','southeast')
    
    % fmin = bestY;
    % Z = (fmin - mu)./sigma;
    % EI = (fmin - mu).*normcdf(Z) + sigma.*normpdf(Z);
    % 
    % yyaxis right
    % plot(xGrid, EI, 'r--','LineWidth',1.5)
    % ylabel('Acquisition (EI)')

end