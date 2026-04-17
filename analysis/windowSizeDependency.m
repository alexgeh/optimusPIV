

D = loadpiv(PIVfolder, 'verbose',false);
x = D.x; y = D.y;
u = D.u; v = D.v;
% vort = D.vort;
u(isnan(u)) = 0;
v(isnan(v)) = 0;

currentXRange = [min(x,[],'all') max(x,[],'all')];
currentYRange = [min(y,[],'all') max(y,[],'all')];
width = diff(currentXRange);
height = diff(currentYRange);

% Define the relative cutoff array (0 to 0.45 -> 0.5 everything is cut)
relCuts = 0:0.01:0.45;
numCuts = length(relCuts);

% Flag to suppress plots inside the turbulenceMetrics function during the loop
doPlot_loop = false; 

% Preallocate an array to store the metrics structure
clear metricsArray; 

for i = 1:numCuts
    relCut = relCuts(i);
    
    % Define the shrinking ranges
    xRange = [currentXRange(1) + relCut*width, currentXRange(2) - relCut*width]; 
    yRange = [currentYRange(1) + relCut*height, currentYRange(2) - relCut*height];
    
    % Crop the flow fields
    [x_crop, y_crop, u_crop, v_crop] = cropFields(xRange, yRange, x, y, u, v);
    
    % Calculate turbulence intensity metrics
    [metrics, ~] = turbulenceMetrics(u_crop, v_crop, x_crop, y_crop, doPlot_loop);
    
    % Store the metrics in a struct array
    if i == 1
        metricsArray = metrics; % Initialize on first pass
    else
        metricsArray(i) = metrics;
    end
end

%% --- Plotting the Convergence of Metrics ---

% Dynamically extract the names of the metrics (e.g., 'TKE', 'Dissipation')
metricNames = fieldnames(metricsArray);
numMetrics = length(metricNames);

% Create a single figure to hold all metric plots
figure('Name', 'Metric Dependency on Window Crop Size', 'Color', 'w', 'Position', [100 100 1200 800]);

% Determine grid size for subplots (e.g., 2x2, 2x3, etc.)
cols = ceil(sqrt(numMetrics));
rows = ceil(numMetrics / cols);

for m = 1:numMetrics
    metricName = metricNames{m};
    
    % Extract the scalar value for this specific metric across all relCuts
    % Using comma-separated list generation for struct arrays
    metricValues = [metricsArray.(metricName)];
    
    % Create subplot for this metric
    subplot(rows, cols, m);
    plot(relCuts, metricValues, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD');
    
    % Formatting
    grid on;
    xlabel('Relative Cutoff (relCut)');
    ylabel(metricName, 'Interpreter', 'none'); % 'none' prevents underscores from becoming subscripts
    title(['Convergence of ', metricName], 'Interpreter', 'none');
    
    % Optional: Add a vertical line when the metric value starts dropping to 0 
    % (since 0.9 relCut means cutting off 180% of the field, which will likely break)
end
