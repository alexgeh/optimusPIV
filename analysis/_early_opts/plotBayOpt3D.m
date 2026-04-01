function plotBayOpt3D(X,Y)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

X1 = X(:,1);
X2 = X(:,2);
    
% Fit GP
gprMdl = fitrgp(X, Y, ...
'KernelFunction','ardsquaredexponential', ...
'BasisFunction','none', ...
'Standardize',true);

% Grid for plotting
x1lin = linspace(min(X1), max(X1), 50);   % resolution
x2lin = linspace(min(X2), max(X2), 50);

[X1g, X2g] = meshgrid(x1lin, x2lin);
Xgrid = [X1g(:), X2g(:)];

% Predictions on grid
[mu, sigma] = predict(gprMdl, Xgrid);

% Reshape to grid form
MU = reshape(mu, size(X1g));
SIGMA = reshape(sigma, size(X1g));

% Mean surface
surf(X1g, X2g, MU, 'EdgeColor','none','FaceAlpha',0.8)
colormap parula
colorbar
xlabel('X1'); ylabel('X2'); zlabel('Predicted objective')
% title('GP Surrogate Surface (mean)')

scatter3(X1, X2, Y, 50, 'k','filled')

% Highlight best point
[bestY, idx] = min(Y);
plot3(X1(idx), X2(idx), bestY, 'ro','MarkerSize',10,'LineWidth',2)
    
% legend('Location','southeast')
end