function visualize_ATG_shaded()
    % Parameters
    nVertMotors  = 8;   % vertical axes (columns)
    nHorizMotors = 7;   % horizontal axes (rows)
    L = 1;              % nominal panel size (edge length of diamond)

    % Actuation parameters
    phiA   = ones(nVertMotors+nHorizMotors,1)*180;     % amplitude [deg]
    f      = ones(nVertMotors+nHorizMotors,1)*0.5;    % frequency [Hz]
    theta0 = linspace(0,2*pi,nVertMotors+nHorizMotors)'; % phase offsets
    phi0   = zeros(nVertMotors+nHorizMotors,1);       % mean offset

    phiFun = @(t, phiA, f, theta0, phi0) ...
        phiA .* sin(2*pi.*f.*t + theta0) + phi0;

    % Time vector
    tSim = linspace(0,10,2000);

    figure;
    hold on;
    axis equal;
    axis off;

    % Fixed field of view (add a margin of 0.5)
    xlim([0, nVertMotors+1]);
    ylim([0, nHorizMotors+2]);  % allow space for extra top row

    for k = 1:length(tSim)
        t = tSim(k);

        % Current motor angles
        phiVals   = phiFun(t, phiA, f, theta0, phi0);
        phiVert   = phiVals(1:nVertMotors);                 % vertical axes
        phiHoriz  = phiVals(nVertMotors+1:end);             % horizontal axes

        cla; % clear axes for redraw

        % --- Draw vertical panels (columns, 8 motors × 8 rows) ---
        for j = 1:nVertMotors
            for i = 1:(nHorizMotors+1)  % one extra row
                x0 = j;
                y0 = i;

                X = [0 L/2 0 -L/2];
                Y = [L/2 0 -L/2 0];

                scaleX = abs(cosd(phiVert(j)));
                scaleY = 1;

                xPanel = x0 + scaleX*X;
                yPanel = y0 + scaleY*Y;

                % Color shading: darker when closed
                c = 0.2 + 0.8*scaleX; % between 0.2 (dark) and 1.0 (bright)
                patch(xPanel,yPanel,[0.2 0.6 c],'EdgeColor','k');
            end
        end

        % --- Draw horizontal panels (rows, 7 motors × 7 columns) ---
        for i = 1:nHorizMotors
            for j = 1:(nVertMotors-1)
                x0 = j+0.5;
                y0 = i+0.5;

                X = [0 L/2 0 -L/2];
                Y = [L/2 0 -L/2 0];

                scaleX = 1;
                scaleY = abs(cosd(phiHoriz(i)));

                xPanel = x0 + scaleX*X;
                yPanel = y0 + scaleY*Y;

                % Color shading: darker when closed
                c = 0.2 + 0.8*scaleY;
                patch(xPanel,yPanel,[c 0.6 0.2],'EdgeColor','k');
            end
        end

        title(sprintf('t = %.2f s',t));
        drawnow;
    end
end

