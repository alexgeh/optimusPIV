% Code to red and plot ATG data
%
% Kenny Breuer Aug 6 2025
clear
close all

%% Parameters to analyse
% Cases:
%

CROSS_CORR = 1;
PLOT_MOVIES = 1;

Nframes_movie = 500;  % Number of frames for the movie

Correlation_size = 100;   % Number of separations to consider in the Xcorrelations

frame_rate = 500;  % Rep rate of images [Hz]  (This is probably in the data structure, but I dont know where)
Nframes = 2500;    % Total number of PIV frames to read

% operational parameter (approx)
params.U = 1;
params.L = 1;
% we f
% figure out the normalization later

for Case = [1 2 3 4];

    if Case == 5
        % Case 5 is different
        folderPIV = 'R:\ENG_Breuer_Shared\group\ATG\ATG_PIV\Wind_Turbine_20250609\ATG_250822_005\StereoPIV_MPd(2x32x32_75%ov)';
    else
        DataDirectory = 'R:\ENG_Breuer_Shared\group\ATG\ATG_PIV\Wind_Turbine_20250609\';
        VC7Directory  = 'StereoPIV_MPd(2x32x32_75%ov)_GPU';
        folderPIV = sprintf('%sATG_250822_%3.3d\\%s', DataDirectory, Case, VC7Directory);
    end

    fprintf('Processing Case %d\n', Case)
    pause(0.1)


    %% Read data - KB version returns a structure - MUCH easier to deal with
    % D is a huge data structure with everything
    D = loadpivKB1(folderPIV,params,'Validate', 0.4, ...
        'nondim', 'frameRange',1:Nframes, "extractAllVariables");
    [Ny, Nx] = size(D.u(:,:,1));

    %% Create a subrange to avoid the boundaries
    RangeX = 3:Nx-2;
    RangeY = 3:Ny-2;

    X = D.x(RangeY, RangeX);
    Y = D.y(RangeY, RangeX);

    %% Re-scale X and Y
    X = X - min(X, [], 'all');
    Y = Y - min(Y, [], 'all');

    % Resample the fields on the smaller domain
    D.u = D.u(RangeY, RangeX,:);
    D.v = D.v(RangeY, RangeX,:);
    D.w = D.w(RangeY, RangeX,:);
    D.vort = D.vort(RangeY, RangeX,:);
    D.corr = D.corr(RangeY, RangeX,:);

    % Redefine Nx and NY based on the new arrays:
    [Ny, Nx] = size(D.u(:,:,1));

    %% Find a mean velocity to scale by
    u_ave_all = mean(D.u, 'all', 'omitnan');
    v_ave_all = mean(D.v, 'all', 'omitnan')/u_ave_all;

    fprintf('Average U Velocity: %6.3f [m/s]\n', u_ave_all);
    fprintf('Average V Velocity: %6.3f [Normalized by U]\n', v_ave_all);

    % Normalize
    D.u    = D.u/u_ave_all;
    D.v    = D.v/u_ave_all;
    D.w    = D.w/u_ave_all;
    D.vort = D.vort/u_ave_all;

    % Calculate Ensemble mean and RMS of the entire field
    u_ave = mean(D.u,    3, 'omitnan');
    v_ave = mean(D.v,    3, 'omitnan');
    w_ave = mean(D.w,    3, 'omitnan');
    o_ave = mean(D.vort, 3, 'omitnan');
    c_ave = mean(D.corr, 3, 'omitnan');

    u_rms = std(D.u,    1, 3, 'omitnan');
    v_rms = std(D.v,    1, 3, 'omitnan');
    w_rms = std(D.w,    1, 3, 'omitnan');
    o_rms = std(D.vort, 1, 3, 'omitnan');
    c_rms = std(D.corr, 1, 3, 'omitnan');

    % Calculate mean of everything
    v_ave_all = mean(v_ave, 'all', 'omitnan');
    w_ave_all = mean(w_ave, 'all', 'omitnan');
    o_ave_all = mean(o_ave, 'all', 'omitnan');
    c_ave_all = mean(c_ave, 'all', 'omitnan');

    u_rms_all = mean(u_rms, 'all', 'omitnan');
    v_rms_all = mean(v_rms, 'all', 'omitnan');
    w_rms_all = mean(w_rms, 'all', 'omitnan');
    o_rms_all = mean(o_rms, 'all', 'omitnan');
    c_rms_all = mean(c_rms, 'all', 'omitnan');

    % Reynolds stress
    r_ave = mean((D.u-1).*(D.v-v_ave_all), 3, 'omitnan');


    % Report the results
    fprintf('U-vel: [%6.2f - %6.2f]; %6.2f +/- %6.2f\n', ...
        min(u_ave, [], 'all', 'omitnan'), max(u_ave, [], 'all', 'omitnan'), u_ave_all, u_rms_all);
    fprintf('V-vel: [%6.2f - %6.2f]; %6.2f +/- %6.2f\n', ...
        min(v_ave, [], 'all', 'omitnan'), max(v_ave, [], 'all', 'omitnan'), v_ave_all, v_rms_all);
    fprintf('W-vel: [%6.2f - %6.2f]; %6.2f +/- %6.2f\n', ...
        min(w_ave, [], 'all', 'omitnan'), max(w_ave, [], 'all', 'omitnan'), w_ave_all, w_rms_all);
    fprintf('O-vel: [%6.2f - %6.2f]; %6.2f +/- %6.2f\n', ...
        min(o_ave, [], 'all', 'omitnan'), max(o_ave, [], 'all', 'omitnan'), o_ave_all, o_rms_all);
    fprintf('C-vel: [%6.2f - %6.2f]; %6.2f +/- %6.2f\n', ...
        min(c_ave, [], 'all', 'omitnan'), max(c_ave, [], 'all', 'omitnan'), c_ave_all, c_rms_all);

    %% Cross correlations
    if CROSS_CORR
        % Choose a smaller range of y-values
        Y_inset = round( (Ny-Correlation_size)/2 ); 
        Y1 = Y_inset;
        Y2 = Ny-Y_inset;
        DX = (X(1,2)-X(1,1));
        lag = (0:(Nx-1)) * DX;
        Ny1 = Y2-Y1+1;
        Ro = 2*zeros(Ny1,Nx);
        Ru = 2*zeros(Ny1,Nx);

        for j = Y1:Y2  % Loop over rows
            for k = 1:Nframes  % loop over frames

                om = D.vort(j,:,k);
                uu = D.u(   j,:,k);

                % Do the correlation for vorticity:

                % replace the NaNs for xcorr
                index = isnan(om);
                om(index) = 0;

                % Do the xcorr of this frame
                temp = xcorr(detrend(om), "normalized");
                
                % Assemble for the average
                Ro(j-Y1+1,:) = Ro(j-Y1+1,:) + temp(Nx:2*Nx-1);

                % Repeat for the u-velocity - remove the NaNs are they the
                % same as for the vorticity? - probably
                index = isnan(uu);
                uu(index) = 0;

                % do the xcorr
                temp = xcorr(detrend(uu), "normalized");

                % Assemble the average
                Ru(j-Y1+1,:) = Ru(j-Y1+1,:) + temp(Nx:2*Nx-1);
            end
        end

        % Calculate the average x-corr
        Ro = Ro/Nframes;
        Ru = Ru/Nframes;

        % Average over y if you want a global xcorr
        Ruu = mean(Ru,1);
        Roo = mean(Ro,1);

        % Get integral quantities
        lambda_u = trapz(lag, Ruu);
        lambda_o = trapz(lag, Roo);

        % find zero crossings
        [rate, count, index] = zerocrossrate(Ruu);
        zero_cross_u = find(index == 1);
        zero_cross_u = zero_cross_u(2)*DX;

        [rate, count, index] = zerocrossrate(Roo);
        zero_cross_o = find(index == 1);
        zero_cross_o = zero_cross_o(2)*DX;

        figure("Position", [100 100 500 500])
        plot(lag, Ruu,lag, Roo)
        set(gca,'FontSize', 14)
        xlabel('\Delta x [m]')
        ylabel('Correlation')
        legend('R_{uu}', 'R_{\omega \omega}')
        xlim([0, Inf])
        grid on

        filename = sprintf('correlation%d', Case);
        eval(['print ' filename ' -depsc'])
        eval(['print ' filename ' -dpng'])
        eval(['savefig ' filename])
    end

    %% Save data
    save_command = sprintf('save ATG%d u_ave v_ave w_ave u_rms v_rms w_rms r_ave X Y', Case);
    eval(save_command)

    %% Generate line plots in the vertical direction - Average in X (second index)
    u_ave_in_x = mean(u_ave, 2, "omitnan");
    u_rms_in_x = mean(u_rms, 2, "omitnan");
    v_ave_in_x = mean(v_ave, 2, "omitnan");
    v_rms_in_x = mean(v_rms, 2, "omitnan");
    w_ave_in_x = mean(w_ave, 2, "omitnan");
    w_rms_in_x = mean(w_rms, 2, "omitnan");
    r_ave_in_x = mean(r_ave, 2, "omitnan");

    figure('Position', [100 100 550 500]);
    subplot(1,2,1)
    plot(Y(:,1), u_ave_in_x)%, Y(:,1), v_ave_in_x, Y(:,1), w_ave_in_x);
    xlabel('Y [m]')
    ylabel('Mean velocity, U/U_o')
    xlim([0.05 0.25])
    ylim([0.5 1.2])
    grid on
    %legend('U', 'V', 'W')
    set(gca,'FontSize',16)

    subplot(1,2,2)
    plot(Y(:,1), u_rms_in_x, Y(:,1), v_rms_in_x, Y(:,1), w_rms_in_x)
    xlabel('Y [m]')
    ylabel('Fluctuations')
    xlim([0.05 0.25])
    ylim([0 0.2])
    grid on
    legend('u''/U_o', 'v''/U_o', 'w''/U_o')
    set(gca,'FontSize',16)

    filename = sprintf('profiles_%d', Case);
    eval(['print ' filename ' -depsc'])
    eval(['print ' filename ' -dpng'])
    eval(['savefig ' filename])

    %% Plot summary data
    figure("Position",[100 100 1600 400])
    fig1 = subplot(2,5,1);
    pcolor(X, Y, u_ave); shading('interp');
    colormap(fig1, slanCM('bubblegum'));
    clim([1-2*u_rms_all  1+2*u_rms_all]);
    colorbar;
    title('u_{ave}')

    fig2 = subplot(2,5,2);
    pcolor(X, Y, v_ave);
    shading('interp');
    colormap(fig2, slanCM('spectral'));
    clim([v_ave_all-2*v_rms_all  v_ave_all+2*v_rms_all ]);
    colorbar;
    title('v_{ave}')

    fig3 = subplot(2,5,3);
    pcolor(X, Y, w_ave);
    shading('interp');
    colormap(fig3, slanCM('spectral'));
    clim([w_ave_all-2*w_rms_all  w_ave_all+2*w_rms_all ]);
    colorbar;
    title('w_{ave}')

    fig4 = subplot(2,5,4);
    pcolor(X, Y, o_ave);
    shading('interp');
    colormap(fig4, slanCM('bwr'));
    clim([o_ave_all-2*o_rms_all  o_ave_all+2*o_rms_all ]);
    colorbar;
    title('\omega_{ave}')

    fig5 = subplot(2,5,5);
    pcolor(X, Y, c_ave);
    shading('interp');
    colormap(fig5, slanCM('voltage'));
    %clim([o_ave_all-2*o_rms_all  o_ave_all+2*o_rms_all ]);
    colorbar;
    title('Corr_{ave}')

    fig6 = subplot(2,5,6);
    pcolor(X, Y, u_rms);
    shading('interp');
    colormap(fig6, slanCM('jet'));
    clim([0 2*u_rms_all]);
    colorbar;
    title('u''')

    fig7 = subplot(2,5,7);
    pcolor(X, Y, v_rms);
    shading('interp');
    colormap(fig7, slanCM('jet'));
    clim([0 2*v_rms_all]);
    colorbar;
    title('v''')

    fig8 = subplot(2,5,8);
    pcolor(X, Y, w_rms);
    shading('interp');
    colormap(fig8, slanCM('jet'));
    clim([0 2*w_rms_all]);
    colorbar;
    title('w''')

    fig9 = subplot(2,5,9);
    pcolor(X, Y, o_rms);
    shading('interp');
    colormap(fig9, slanCM('jet'));
    clim([0 2*o_rms_all]);
    colorbar;
    title('\omega''')

    fig10 = subplot(2,5,10);
    pcolor(X, Y, c_rms);
    shading('interp');
    colormap(fig10, slanCM('jet'));
    clim([0 2*o_rms_all]);
    colorbar;
    title('C_{rms}''')

    filename = sprintf('summary%d', Case);
    eval(['print ' filename ' -depsc'])
    eval(['print ' filename ' -dpng'])
    eval(['savefig ' filename])


    %% Make movies - edit as necessary
    if PLOT_MOVIES
        figure('Position', [100 100 550 500]);
        vidfile = VideoWriter(sprintf('uvel_%d.mp4', Case),'MPEG-4');
        open(vidfile);
        for i = 1:Nframes_movie
            pcolor(X, Y, D.u(:,:,i));
            shading('interp');
            colormap(slanCM('jet'));
            clim([1-3*u_rms_all  1+3*u_rms_all]);
            c = colorbar;
            c.Label.String = 'u/U';
            xlabel('x [m]')
            ylabel('y [m]')
            set(gca, 'FontSize', 14)
            writeVideo(vidfile, getframe(gcf));
        end
        close(vidfile)

        %% Vorticity movie
        figure('Position', [100 100 550 500]);
        vidfile = VideoWriter(sprintf('vort_%d.mp4', Case),'MPEG-4');
        open(vidfile);
        for i = 1:Nframes_movie
            pcolor(X, Y, D.vort(:,:,i));
            shading('interp');
            axis equal
            colormap(slanCM('fusion'));
            clim([-2*o_rms_all  2*o_rms_all]);
            c = colorbar;
            c.Label.String = 'vorticity, \omega L/U';
            xlabel('x [m]')
            ylabel('y [m]')
            set(gca, 'FontSize', 14)
            xL=xlim;
            yL=ylim;
            time_stamp = sprintf('t = %6.3f s', i/frame_rate);
            text(0.95*xL(2),0.95*yL(2),time_stamp,...
                'BackgroundColor', 'white', 'EdgeColor', 'black', ...
                'FontSize', 16, 'HorizontalAlignment','right','VerticalAlignment','top')
            writeVideo(vidfile, getframe(gcf));
        end
        close(vidfile)
    end
end