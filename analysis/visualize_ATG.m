function visualize_ATG(phiA, f, theta0, phi0, tSim, saveFolder, filePrefix)
    % Parameters
    nVertMotors  = 8;   % vertical axes (columns)
    nHorizMotors = 7;   % horizontal axes (rows)
    L = 1;              % nominal panel size (edge length of diamond)

    phiFun = @(t, phiA, f, theta0, phi0) ...
        phiA .* sin(2*pi.*f.*t + theta0) + phi0;

    % Create output folder if saving requested
    if nargin > 5 && ~isempty(saveFolder)
        if ~exist(saveFolder,'dir')
            mkdir(saveFolder);
        end
    end

    fig = figure('Visible','off'); % off for faster export
    hold on;
    axis equal;
    axis off;

    % Fixed field of view (add a margin of 0.5)
    xlim([0, nVertMotors+1]);
    ylim([0, nHorizMotors+2]);

    for k = 1:length(tSim)
        t = tSim(k);

        % Current motor angles
        phiVals   = phiFun(t, phiA, f, theta0, phi0);
        phiVert   = phiVals(1:nVertMotors);     % vertical axes
        phiHoriz  = phiVals(nVertMotors+1:end); % horizontal axes

        cla; % clear axes for redraw

        % --- Draw vertical panels (columns, 8 motors × 8 rows) ---
        for j = 1:nVertMotors
            for i = 1:(nHorizMotors+1)  % one extra row
                % Position of panel center
                x0 = j;
                y0 = i;

                % Diamond shape
                X = [0 L/2 0 -L/2];
                Y = [L/2 0 -L/2 0];

                % Scale in x according to vertical motor j
                scaleX = abs(cosd(phiVert(j)));
                xPanel = x0 + scaleX*X;
                yPanel = y0 + Y;

                patch(xPanel,yPanel,[0.2 0.6 0.9],'EdgeColor','k');
            end
        end

        % --- Draw horizontal panels (rows, 7 motors × 7 columns) ---
        for i = 1:nHorizMotors
            for j = 1:(nVertMotors-1)
                x0 = j+0.5;
                y0 = i+0.5;

                X = [0 L/2 0 -L/2];
                Y = [L/2 0 -L/2 0];

                % Scale in y according to horizontal motor i
                scaleY = abs(cosd(phiHoriz(i)));
                xPanel = x0 + X;
                yPanel = y0 + scaleY*Y;

                patch(xPanel,yPanel,[0.9 0.6 0.2],'EdgeColor','k');
            end
        end

%         title(sprintf('t = %.2f s',t));

        % Save frame if requested
        if nargin > 5 && ~isempty(saveFolder)
            fname = sprintf('%s/%s_%04d.png',saveFolder,filePrefix,k);

            % Define your fixed export size in inches (or cm)
            width = 5;   % inches
            height = 5;  % inches
            
            set(fig, 'Units', 'inches');
            set(fig, 'Position', [1 1 width height]);   % on-screen size (optional)
            
            set(fig, 'PaperUnits', 'inches');
            set(fig, 'PaperSize', [width height]);
            set(fig, 'PaperPositionMode', 'manual');
            set(fig, 'PaperPosition', [0 0 width height]);

            set(fig,'PaperPositionMode','auto');

            set(gca(), 'color', 'w');
            export_fig(fname, '-transparent', -r300')

%             print(fig,fname,'-dpng','-r300');
        else
            drawnow;
        end
    end

    close(fig);
end

