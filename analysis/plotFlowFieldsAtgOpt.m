%% Script to analyze ATG PIV optimization
%#ok<*SAGROW> 
clear


%% Processing parameters:
localPC = 1; % 1: office PC, 2: Legion (laptop)
optID = 7;
plotPIV = false; % Plot PIV - !! Will take VEEERY long !!
% L = 0.123; % Characteristic length [m], diagonal length of panels
% L = 0.087 / 2; % Characteristic length [m], width of panels
L = 0.087; % Characteristic length [m], width of panels
PIVdx = 0.001630007922649; % Pixel length of PIV frames


%% File system thingies:
switch optID
    case 3 % Synchronous ATG control - TI_target = 0.2, homogenous, isotropic
        projStr = "20251017_ATG_bayes_opt_3";
        xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
        yRange = [-0.0650 0.1396];
        nPlotFrames = 200;
        TI_target = 0.2; % Target turbulence intensity the optimization was driven towards
    % Cases 4,5,6:
    % Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient
    case 4 % !! LAST 10 PIV FRAMES FAULTY !! -> optim. not usable
        projStr = "20251022_ATG_bayes_opt_4";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190; % LAST 10 FRAMES NOT ILLUMINATED
        TI_target = 0.2; % Target turbulence intensity that the optimization was driven towards
        dudy_target = -2.5; % Target velocity gradient that the optimization was driven towards
    case 5 % !! DID NOT CONVERGE !! -> optim. not usable
        projStr = "20251023_ATG_bayes_opt_5";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
        TI_target = 0.2; % Target turbulence intensity the optimization was driven towards
        dudy_target = -2.5; % Target velocity gradient that the optimization was driven towards
    case 6 % succesful run of "Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient"
        projStr = "20251023_ATG_bayes_opt_6";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
        TI_target = 0.2; % Target turbulence intensity the optimization was driven towards
        dudy_target = -2.5; % Target velocity gradient that the optimization was driven towards
    case 7 % Gradient ATG control - TI_target = 0.2, dTIdy = -0.2, min vel gradient
        projStr = "20251024_ATG_bayes_opt_7";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
        TI_target = 0.2; % Target turbulence intensity the optimization was driven towards
        dTIdy_target = -0.2; % Target turbulence intensity gradient that the optimization was driven towards
    otherwise
        error('opt ID not found - cannot continue')
end

% Set up local file directories:
if localPC == 1
    % office PC
    rootDataDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\";
    plotDir = fullfile("R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\", projStr);
elseif localPC == 2
    % laptop
    rootDataDir = "C:\Users\alexg\Downloads\TMPDATA_2025_optimusPIV\fullOptimizations\";
    plotDir = fullfile("C:\Users\alexg\Downloads\TMPDATA_2025_optimusPIV\plots\", projStr);
end
projDir = fullfile(rootDataDir, projStr);
pivFolder = fullfile(projDir, "proc_PIV");
variousColorMaps();


%% Stack all data together
projStr_array(3) = "20251017_ATG_bayes_opt_3";
projStr_array(5) = "20251023_ATG_bayes_opt_5";
projStr_array(6) = "20251023_ATG_bayes_opt_6";
projStr_array(7) = "20251024_ATG_bayes_opt_7";

stack_J = [];
stack_freq = [];
stack_ampl = [];
stack_offset = [];
stack_TI_mean = [];
stack_TIgrad_mean = [];
stack_velgrad_mean = [];
stack_aniso_mean = [];
stack_CV = [];  

for caseIdx = [3,5,6,7]
    dataDir = fullfile(rootDataDir, projStr_array(caseIdx));
    load(fullfile(dataDir, "workspaceOptimization.mat"))

    % [metrics, fields] = turbulenceMetrics(u,v,x,y,doPlot);

    J = [optResults.J];
    freq = [optResults.freq];
    % alpha = [optResults.alpha];
    % relBeta = [optResults.relBeta];
    ampl = [optResults.ampl];
    offset = [optResults.offset];
    
    nIter = length(J);
    
    clearvars J_TI J_velgrad J_hom_dUdy J_hom_TIgrad J_hom_CV J_aniso TI_mean TI_std TIgrad_mean TIgrad_std CV velgrad_mean aniso_mean
    for iter = 1:nIter
        J_TI(iter) = optResults(iter).J_comp.J_TI; 
        if optID == 3
            J_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
        elseif optID == 4 || optID == 5
            J_hom_dUdy(iter) = optResults(iter).J_comp.J_hom_dUdy;
        end
        J_hom_TIgrad(iter) = optResults(iter).J_comp.J_hom_TIgrad;
        J_hom_CV(iter) = optResults(iter).J_comp.J_hom_CV;
        J_aniso(iter) = optResults(iter).J_comp.J_aniso;
        
        TI_mean(iter) = optResults(iter).metrics.TI_mean;
        TI_std(iter) = optResults(iter).metrics.TI_std;
        TIgrad_mean(iter) = optResults(iter).metrics.TIgrad_mean;
        TIgrad_std(iter) = optResults(iter).metrics.TIgrad_std;
        CV(iter) = optResults(iter).metrics.CV;
        velgrad_mean(iter) = optResults(iter).metrics.velgrad_mean;
        aniso_mean(iter) = optResults(iter).metrics.aniso_mean;
    end

    stack_J = [stack_J, J];
    stack_freq = [stack_freq, freq];
    stack_ampl = [stack_ampl, ampl];
    stack_offset = [stack_offset, offset];
    stack_TI_mean = [stack_TI_mean, TI_mean];
    stack_TIgrad_mean = [stack_TIgrad_mean, TIgrad_mean];
    stack_velgrad_mean = [stack_velgrad_mean, velgrad_mean];
    stack_aniso_mean = [stack_aniso_mean, aniso_mean];
    stack_CV = [stack_CV, CV];
end
clearvars J_TI J_velgrad J_hom_dUdy J_hom_TIgrad J_hom_CV J_aniso TI_mean TI_std TIgrad_mean TIgrad_std CV velgrad_mean aniso_mean


%%
load(fullfile(projDir, "workspaceOptimization.mat"))
J = [optResults.J];
freq = [optResults.freq];
alpha = [optResults.alpha];
relBeta = [optResults.relBeta];
ampl = [optResults.ampl];
offset = [optResults.offset];

if optID == 4 || optID == 5  || optID == 6 || optID == 7
    ampgrad = [optResults.ampgrad];
    offsetgrad = [optResults.offsetgrad];
end

nIter = length(J);
for iter = 1:nIter
    J_TI(iter) = optResults(iter).J_comp.J_TI; 
    if optID == 3
        J_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
    elseif optID == 4 || optID == 5  || optID == 6
        J_hom_dUdy(iter) = optResults(iter).J_comp.J_hom_dUdy;
        dudy_mean(iter) = optResults(iter).metrics.dudy_mean;
    elseif optID == 7
        J_hom_dTIdy(iter) = optResults(iter).J_comp.J_hom_dTIdy;
        dudy_mean(iter) = optResults(iter).metrics.dudy_mean;
        dTIdy_mean(iter) = optResults(iter).metrics.dTIdy_mean;
    end
    J_hom_TIgrad(iter) = optResults(iter).J_comp.J_hom_TIgrad;
    J_hom_CV(iter) = optResults(iter).J_comp.J_hom_CV;
    J_aniso(iter) = optResults(iter).J_comp.J_aniso;
    
    TI_mean(iter) = optResults(iter).metrics.TI_mean;
    TI_std(iter) = optResults(iter).metrics.TI_std;
    TIgrad_mean(iter) = optResults(iter).metrics.TIgrad_mean;
    TIgrad_std(iter) = optResults(iter).metrics.TIgrad_std;
    CV(iter) = optResults(iter).metrics.CV;
    velgrad_mean(iter) = optResults(iter).metrics.velgrad_mean;
    aniso_mean(iter) = optResults(iter).metrics.aniso_mean;
end

[nX,nY] = size(optResults(1).fields.U);

x = (0:nY-1) * PIVdx;
y = (0:nX-1) * PIVdx;

% Create coordinate matrices
[X, Y] = meshgrid(x, y);

% return


%% Plot all flow fields:
if plotPIV
%% Average Streamwise Velocity Field
targetFolder = fullfile(plotDir, "flowfields", "U");
ensureTopLevelFolder(targetFolder);
figure(501)
% for iter = 1:nIter
for iter = [23, 33, 28, 14] % Cases to present at DFD - opt 3
    fname = fullfile(targetFolder, "U_" + mpt2str(iter) + ".png");
    
    toplot = optResults(iter).fields.U;
    meanU = mean(toplot(:));
    toplot = toplot / meanU;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(X/L, Y/L, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    axis equal;
    colormap('jet');
    clim(limits);
    hcb=colorbar;
    hcb.Label.Interpreter = 'latex';
    hcb.Label.String = '$$U / \bar{U}$$';
    hcb.FontSize = 14; % Set the font size of the tick labels
%     clim([0.90 1.10]);
    set(hcb,'YTick',0.96:0.02:1.04);
    hcb.Label.FontSize = 14; % Set desired font size
    xlabelg('$$x/L$$'); ylabelg('$$y/L$$'); 
    ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
    xticks(0:1:4); yticks(0:1:4);
    set(gcf, 'Color', 'white')

    export_fig(fname, '-png', '-transparent', '-opengl','-r600');
end


%% Average Crossstream Velocity Field
targetFolder = fullfile(plotDir, "flowfields", "V");
ensureTopLevelFolder(targetFolder);
figure(502)
for iter = 1:nIter
    fname = fullfile(targetFolder, "V_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.V;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    colormap('jet')
    a=colorbar;
    a.Label.String = 'V';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Turbulence Intensity Field
targetFolder = fullfile(plotDir, "flowfields", "TI");
ensureTopLevelFolder(targetFolder);
figure(503)
for iter = 1:nIter
    fname = fullfile(targetFolder, "TI_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.TI;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'TI';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Anisotropy Field
targetFolder = fullfile(plotDir, "flowfields", "aniso");
ensureTopLevelFolder(targetFolder);
figure(504)
for iter = 1:nIter
    fname = fullfile(targetFolder, "aniso_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.aniso;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'aniso';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Velocity Gradient Field
targetFolder = fullfile(plotDir, "flowfields", "velgrad");
ensureTopLevelFolder(targetFolder);
figure(505)
for iter = 1:nIter
    fname = fullfile(targetFolder, "velgrad_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.velgrad;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'velgrad';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Turbulence Intensity Gradient Field
targetFolder = fullfile(plotDir, "flowfields", "TIgrad");
ensureTopLevelFolder(targetFolder);
figure(506)
for iter = 1:nIter
    fname = fullfile(targetFolder, "TIgrad_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.TIgrad;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'TIgrad';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TIME RESOLVED PLOTS:
% Create folder for all time-resolved flow field plots
ensureTopLevelFolder(fullfile(plotDir, "flowfields", "u_timeres"));
ensureTopLevelFolder(fullfile(plotDir, "flowfields", "v_timeres"));
ensureTopLevelFolder(fullfile(plotDir, "flowfields", "vort_timeres"));

for iter = 23%1:nIter
    folder = fullfile(pivFolder, sprintf('ms%.4d', iter));
    D = loadpiv(folder);
    x = D.x; y = D.y;
    u = D.u; v = D.v;
    nFrames = size(u,3);
    vort = D.vort;
%     u(isnan(u)) = 0;
%     v(isnan(v)) = 0;
    
    [x_crop,y_crop,u_crop,v_crop,vort_crop] = cropFields(xRange,yRange,x,y,u,v,vort);
    x_crop = x_crop - x_crop(1);
    y_crop = y_crop - y_crop(1);
    
    %% Streamwise Velocity Field
    targetFolder = fullfile(plotDir, "flowfields", "u_timeres", sprintf('ms%.4d', iter));
    ensureTopLevelFolder(targetFolder);
    figure(507)
    for iFrame = 1:nPlotFrames
        fname = fullfile(targetFolder, "u_" + mpt2str(iFrame) + ".png");

        toplot = u_crop(:,:,iFrame) / mean(u_crop(:));
        limits = [mean(u_crop(:))-2*std(u_crop(:)) mean(u_crop(:))+2*std(u_crop(:))] / mean(u_crop(:));
        nLevel = 100;
        [C,h] = contourf(x_crop/L/2, y_crop/L/2, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        axis equal;
        colormap('jet');
        clim(limits);
        hcb=colorbar;
        hcb.Label.Interpreter = 'latex';
        hcb.Label.String = '$$U / \bar{U}$$';
        hcb.FontSize = 14; % Set the font size of the tick labels
    %     clim([0.90 1.10]);
%         set(hcb,'YTick',0.96:0.02:1.04);
        hcb.Label.FontSize = 14; % Set desired font size
        xlabelg('$$x/L$$'); ylabelg('$$y/L$$'); 
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
        xticks(0:1:4); yticks(0:1:4);
        set(gcf, 'Color', 'white')

        export_fig(fname, '-png', '-opengl','-r600');
        pause(0.1)
    end

    %% Crossstream Velocity Field
    targetFolder = fullfile(plotDir, "flowfields", "v_timeres", sprintf('ms%.4d', iter));
    ensureTopLevelFolder(targetFolder);
    figure(508)
    for iFrame = 1:nPlotFrames
        fname = fullfile(targetFolder, "v_" + mpt2str(iFrame) + ".png");
        toplot = v_crop(:,:,iFrame);
        limits = [mean(v_crop(:))-2*std(v_crop(:)) mean(v_crop(:))+2*std(v_crop(:))];
        nLevel = 100;
        [C,h] = contourf(x_crop, y_crop, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colormap('jet')
        a=colorbar;
        a.Label.String = 'v';
        clim(limits)
        export_fig(fname, '-png', '-opengl','-r600');
    end

    %% Vorticity Field
    targetFolder = fullfile(plotDir, "flowfields", "vort_timeres", sprintf('ms%.4d', iter));
    ensureTopLevelFolder(targetFolder);
    figure(509)
    for iFrame = 1:nPlotFrames
        fname = fullfile(targetFolder, "vort_" + mpt2str(iFrame) + ".png");
        toplot = vort_crop(:,:,iFrame);
        limits = [-2*std(vort_crop(:)) 2*std(vort_crop(:))];
        nLevel = 100;
        [C,h] = contourf(x_crop, y_crop, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colormap(uColorMap)
        a=colorbar;
        a.Label.String = 'vort';
        clim(limits)
        export_fig(fname, '-png', '-opengl','-r600');
    end
end


%% MAKE VIDEOS FROM IMAGES
currentDir = pwd();
for iter = 1:nIter
    % time-resolved streamwise velocity 
    targetFolder = fullfile(plotDir, "flowfields", "u_timeres", sprintf('ms%.4d', iter));
    videoCmd = 'ffmpeg -framerate 5 -start_number 1 -i u_mpt%03d.png -c:v libx264 -preset fast -profile:v high -level:v 4.0 -pix_fmt yuv420p -crf 8 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" avideo5fps.avi';
    cd(targetFolder)
    status = system(videoCmd);

    % time-resolved crossstream velocity 
    targetFolder = fullfile(plotDir, "flowfields", "v_timeres", sprintf('ms%.4d', iter));
    videoCmd = 'ffmpeg -framerate 5 -start_number 1 -i v_mpt%03d.png -c:v libx264 -preset fast -profile:v high -level:v 4.0 -pix_fmt yuv420p -crf 8 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" avideo5fps.avi';
    cd(targetFolder)
    status = system(videoCmd);

    % time-resolved vorticity 
    targetFolder = fullfile(plotDir, "flowfields", "vort_timeres", sprintf('ms%.4d', iter));
    videoCmd = 'ffmpeg -framerate 5 -start_number 1 -i vort_mpt%03d.png -c:v libx264 -preset fast -profile:v high -level:v 4.0 -pix_fmt yuv420p -crf 8 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" avideo5fps.avi';
    cd(targetFolder)
    status = system(videoCmd);
end
cd(currentDir) % go back to original directory

% %%%%%%%%%%%%%%
% END OF PIV PLOTTING 
end


%% Optimization convergence over iterations
plotConvergence(J);
ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
% ylim([0 0.2]); 
% yticks(0:0.05:0.3) % Case 3
% yticks(0:0.2:1.0) % Case 7
% legend('Location', 'northwest')
fname = fullfile(plotDir, 'X_VS_Iterations', 'fitness.svg');
set(gcf, 'Color', 'white')
export_fig(fname, '-transparent', '-svg');


%% TI metric over iterations
plotTargetMetric(TI_mean, 0.2, 5)
ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
xlabelg('Iteration'); ylabelg('$$TI$$');
ylim([0 0.35]);
yticks(0:0.1:0.4);
fname = fullfile(plotDir, 'X_VS_Iterations', 'TIMetric.svg');
set(gcf, 'Color', 'white')
export_fig(fname, '-transparent', '-svg');


%% TI gradient metric over iterations
plotTargetMetric(dTIdy_mean, dTIdy_target, 5)
ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
% ylim([0 0.35]);
% yticks(0:0.1:0.4);
ylabelg('$$dTI / dy \; [m^{-1}]$$');
fname = fullfile(plotDir, 'X_VS_Iterations', 'dTIdy_metric.svg');
set(gcf, 'Color', 'white');
export_fig(fname, '-transparent', '-svg');


%% Display best / worst
[bestJ,ibest] = min(J);
[worstJ,iworst] = max(J);
fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
ibest, freq(ibest), ampl(ibest), offset(ibest), J(ibest), TI_mean(ibest));
fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
iworst, freq(iworst), ampl(iworst), offset(iworst), J(iworst), TI_mean(iworst));


%%



%% Plotting of metrics
yRangeArray = linspace(0,yRange(2)-yRange(1),length(mean(optResults(1).fields.U,2))) / L;
yMinToMax = [yRangeArray(1), yRangeArray(end)];
yHeight = yRange(2)-yRange(1);

% for casei = [23,14,20,28,33] % For homogenous, isotropic (opt 3)
casei = ibest;
% U
U_mean = mean(optResults(casei).fields.U,'all');
toplot = mean(optResults(casei).fields.U,2) / U_mean;
figure(); hold on;
plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', 'black');
plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
xlabelg("$$y / L$$"); ylabelg("$$U / \bar{U}$$");
xlim(yMinToMax);
% ylim([0.8 1.2]);
box on
ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
% title(ibest)
fname = fullfile(plotDir, 'distributions', 'U_mean', [sprintf('U_mean_%.4d_zoom.svg', casei)]);
set(gcf, 'Color', 'white')
export_fig(fname, '-transparent', '-svg');

% TI
toplot = mean(optResults(casei).fields.TI,2);
figure(); hold on;
plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
% plot(yMinToMax, TI_target*ones(2,1), "LineWidth", 1, 'Color', 'black');
plot(yMinToMax, mean(toplot)*ones(2,1), '--', "LineWidth", 1, 'Color', lightOrange);
xlabelg("$$y / L$$"); ylabelg("$$TI$$");
xlim(yMinToMax);
% ylim([0 0.35]); yticks(0:0.1:0.4);
box on
ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
% title(ibest)
fname = fullfile(plotDir, 'distributions', 'TI_mean', [sprintf('TI_mean_%.4d_zoom.svg', casei)]);
set(gcf, 'Color', 'white')
export_fig(fname, '-transparent', '-svg');

% end

switch optID
    case 6
        % U
        U_mean = mean(optResults(ibest).fields.U,'all');
        toplot = mean(optResults(ibest).fields.U,2) / U_mean;
        dUdy_mean = mean(optResults(ibest).fields.dUdy,'all') / U_mean;
        dUdy_Delta = dUdy_mean*yHeight/2;

        figure(); hold on;
        % plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', 'black');
        plot(yMinToMax, [mean(toplot)-dUdy_Delta, mean(toplot)+dUdy_Delta], "LineWidth", 1, 'Color', lightOrange)
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
        xlabelg("$$y / L$$"); ylabelg("$$U / U_\infty$$");
        xlim(yMinToMax)
        box on
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;


        % dU_dy
        toplot = mean(optResults(ibest).fields.dUdy,2);
        figure(); hold on;
        plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', lightOrange);
        plot(yMinToMax, dudy_target*ones(2,1), "LineWidth", 1, 'Color', 'black');
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
        xlabelg("$$y / L$$"); ylabelg("$$dU/dy$$");
        xlim(yMinToMax)
        box on
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;

        % NEW du_dy
        U_mean = mean(optResults(casei).fields.U,'all');
        toplot = mean(optResults(casei).fields.U,2) / U_mean;
        dUdy_mean = mean(optResults(ibest).fields.dUdy,'all');
        dUdy_Delta = dUdy_mean*yHeight/2 / U_mean;
        figure(); hold on;
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
        plot(yMinToMax, [mean(toplot)-dUdy_Delta, mean(toplot)+dUdy_Delta], '--', "LineWidth", 1, 'Color', lightOrange);
        xlabelg("$$y / L$$"); ylabelg("$$U / \bar{U}$$");
        xlim(yMinToMax);
        ylim([0.8 1.2]);
        box on
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
        % title(ibest)
        fname = fullfile(plotDir, 'distributions', 'U_mean', [sprintf('U_mean_%.4d.svg', casei)]);
        set(gcf, 'Color', 'white')
        export_fig(fname, '-transparent', '-svg');

        % TI
        toplot = mean(optResults(ibest).fields.TI,2);
        dTIdy_mean = mean(optResults(ibest).fields.dTIdy,'all');
        dTIdy_Delta = dTIdy_mean*yHeight/2;

        figure(); hold on;
        plot(yRangeArray, toplot);
        % plot([0 yHeight], mean(toplot)*ones(2,1));
        plot(yMinToMax, [mean(toplot)-dTIdy_Delta, mean(toplot)+dTIdy_Delta]);
        xlabelg("$$y [m]$$"); ylabelg("$$TI$$");

        % dTI_dy
        toplot = mean(optResults(ibest).fields.dTIdy,2);
        figure(); hold on;
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
        plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', lightOrange);
        % plot(yMinToMax, -0.2*ones(2,1), 'Color', 'black');
        xlabelg("$$y / L$$"); ylabelg("$$dTI/dy$$");
        xlim(yMinToMax)
        box on;
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;

        case 7

        % TI
        toplot = mean(optResults(casei).fields.TI,2);
        dTIdy_mean = mean(optResults(ibest).fields.dTIdy,'all');
        dTIdy_Delta = dTIdy_mean*yHeight/2;

        figure(); hold on;
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
%         plot(yMinToMax, TI_target*ones(2,1), "LineWidth", 1, 'Color', 'black');
%         plot(yMinToMax, mean(toplot)*ones(2,1), '--', "LineWidth", 1, 'Color', lightOrange);
        plot(yMinToMax, [mean(toplot)-dTIdy_Delta, mean(toplot)+dTIdy_Delta], '--', "LineWidth", 1, 'Color', lightOrange);
        xlabelg("$$y / L$$"); ylabelg("$$TI$$");
        xlim(yMinToMax);
        ylim([0 0.35]); yticks(0:0.1:0.4);
        box on
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
        % title(ibest)
        fname = fullfile(plotDir, 'distributions', 'TI_mean', [sprintf('dTIdy_%.4d.svg', casei)]);
        set(gcf, 'Color', 'white')
        export_fig(fname, '-transparent', '-svg');

        % dTI_dy
        toplot = mean(optResults(ibest).fields.dTIdy,2);
        figure(); hold on;
        plot(yRangeArray, toplot, "LineWidth", 2, 'Color', defaultOrange);
        plot(yMinToMax, mean(toplot)*ones(2,1), "LineWidth", 1, 'Color', lightOrange);
        % plot(yMinToMax, -0.2*ones(2,1), 'Color', 'black');
        xlabelg("$$y / L$$"); ylabelg("$$dTI/dy$$");
        xlim(yMinToMax)
        box on;
        ax = gca; ax.XAxis.FontSize = 14; ax.YAxis.FontSize = 14;
end


%% best case 6
% yRangeArray = linspace(0,yRange(2)-yRange(1),length(toplot));
% yHeight = yRange(2)-yRange(1);
% 
% % U
% toplot = mean(optResults(ibest).fields.U,2);
% dUdy_mean = mean(optResults(ibest).fields.dUdy,'all');
% dUdy_Delta = dUdy_mean*yHeight/2;
% 
% figure(); hold on;
% plot(yRangeArray, toplot);
% % plot([0 yHeight], mean(toplot)*ones(2,1));
% plot([0 yHeight], [mean(toplot)-dUdy_Delta, mean(toplot)+dUdy_Delta]);
% % plot(yRange-yRange(1), 0*ones(2,1), 'Color', 'black');
% xlabelg("$$y [m]$$"); ylabelg("$$U$$");
% 
% % dU_dy
% toplot = mean(optResults(ibest).fields.dUdy,2);
% figure(); hold on;
% plot(yRangeArray, toplot);
% plot([0 yHeight], mean(toplot)*ones(2,1));
% plot([0 yHeight], -2.5*ones(2,1), 'Color', 'black');
% xlabelg("$$y [m]$$"); ylabelg("$$dU/dy$$");
% 
% % TI
% toplot = mean(optResults(ibest).fields.TI,2);
% dTIdy_mean = mean(optResults(8).fields.dTIdy,'all');
% dTIdy_Delta = dTIdy_mean*yHeight/2;
% 
% figure(); hold on;
% plot(yRangeArray, toplot);
% plot([0 yHeight], mean(toplot)*ones(2,1));
% % plot([0 yHeight], [mean(toplot)-dTIdy_Delta, mean(toplot)+dTIdy_Delta]);
% xlabelg("$$y [m]$$"); ylabelg("$$TI$$");
% 
% % dTI_dy
% toplot = mean(optResults(ibest).fields.dTIdy,2);
% figure(); hold on;
% plot(linspace(0,yRange(2)-yRange(1),length(toplot)), toplot);
% plot([0 yHeight], mean(toplot)*ones(2,1));
% plot([0 yHeight], 0*ones(2,1), 'Color', 'black');
% xlabelg("$$y [m]$$"); ylabelg("$$dTI/dy$$");


%%
figure, scatter(stack_TI_mean, stack_velgrad_mean, [], 0.5*[1 1 1])
hold on, scatter(TI_mean, velgrad_mean, [], defaultOrange, 'filled')


%% Amplitude and TI relationship
plotMetricRelation(stack_ampl, stack_TI_mean, 'fit', true);
hold on, scatter(ampl, TI_mean, [], defaultOrange, 'filled')
xlabelg('amplitude: $$A$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14; 


%% Frequency and TI relationship
plotMetricRelation(stack_freq, stack_TI_mean);
hold on, scatter(freq, TI_mean, [], defaultOrange, 'filled')
xlabelg('frequency: $$f$$ [Hz]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%% Offset and TI relationship
plotMetricRelation(stack_offset, stack_TI_mean);
hold on, scatter(offset, TI_mean, [], defaultOrange, 'filled')
xlabelg('offset: $$\theta$$ [deg]'); ylabelg('turbulence intensity: $$TI$$');
ax = gca; ax.FontSize = 14;


%%
figure, scatter(stack_freq, stack_TI_mean, [], 0.5*[1 1 1])
hold on, scatter(freq, TI_mean, [], defaultOrange, 'filled')


%%
figure, scatter(stack_offset, stack_TI_mean, [], 0.5*[1 1 1])
hold on, scatter(offset, TI_mean, [], defaultOrange, 'filled')


%%
figure, scatter(stack_offset, stack_aniso_mean, [], 0.5*[1 1 1])
hold on, scatter(offset, aniso_mean, [], defaultOrange, 'filled')

if optID == 6

%% Only last opt (TI grad)
inputData = [freq', ampl', offset', ampgrad', offsetgrad']; outputData = [TI_mean', TIgrad_mean', dudy_mean',CV',aniso_mean'];
paramNames = {'freq','ampl','offset','ampgrad','offsetgrad'};
metricNames = {'TI_mean','TIgrad_mean','dudy_mean','CV','aniso_mean'};
R = corr([inputData outputData],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:length(paramNames), length(paramNames)+1:length(paramNames)+length(metricNames)); % adjust if different sizes
corrTable = array2table(Rpm, 'RowNames', paramNames, 'VariableNames',metricNames);

%% correlation table
figure('Name','Input–Output Correlation Table');
imagesc(Rpm);% show correlation values as color
axis equal tight;
colorRange = [      % red - white - green
    1.00  0.80  0.80   
    1.00  0.88  0.88
    1.00  0.94  0.94
    1.00  0.97  0.97
    1.00  1.00  1.00   
    0.97  1.00  0.97
    0.94  1.00  0.94
    0.88  1.00  0.88
    0.80  1.00  0.80];
colormap(colorRange);  
clim([-1 1]);   % correlation range
colorbar;
% axes labels
set(gca, 'XTick', 1:numel(metricNames), 'XTickLabel', metricNames, ...
         'YTick', 1:numel(paramNames), 'YTickLabel', paramNames, ...
         'TickLabelInterpreter','none', 'XTickLabelRotation',45);
% xlabel('Input parameters'); ylabel('Output metrics');
ax = gca;
ax.FontSize = 16;
% title('Correlation between inputs and outputs');

% overlay numeric correlation values
for i = 1:size(Rpm,1)
    for j = 1:size(Rpm,2)
        val = Rpm(i,j);
        % overlay text
        text(j, i, sprintf('%.2f', val), ...
            'HorizontalAlignment','center', ...
            'FontSize',14);
    end
end

elseif optID == 7

%% Only last opt (TI grad)
inputData = [freq', ampl', offset', ampgrad', offsetgrad']; outputData = [TI_mean', dTIdy_mean', velgrad_mean',CV',aniso_mean'];
paramNames = {'freq','ampl','offset','ampgrad','offsetgrad'};
metricNames = {'TI_mean','dTIdy_mean','velgrad_mean','CV','aniso_mean'};
R = corr([inputData outputData],'rows','complete'); % get full correl matrix
% extract param vs metric block
Rpm = R(1:length(paramNames), length(paramNames)+1:length(paramNames)+length(metricNames)); % adjust if different sizes
corrTable = array2table(Rpm, 'RowNames', paramNames, 'VariableNames',metricNames);

%% correlation table

figure('Name','Input–Output Correlation Table');
imagesc(Rpm);% show correlation values as color
axis equal tight;
colorRange = [      % red - white - green
    1.00  0.80  0.80   
    1.00  0.88  0.88
    1.00  0.94  0.94
    1.00  0.97  0.97
    1.00  1.00  1.00   
    0.97  1.00  0.97
    0.94  1.00  0.94
    0.88  1.00  0.88
    0.80  1.00  0.80];
colormap(colorRange);  
clim([-1 1]);   % correlation range
colorbar;
% axes labels
set(gca, 'XTick', 1:numel(metricNames), 'XTickLabel', metricNames, ...
         'YTick', 1:numel(paramNames), 'YTickLabel', paramNames, ...
         'TickLabelInterpreter','none', 'XTickLabelRotation',45);
% xlabel('Input parameters'); ylabel('Output metrics');
ax = gca;
ax.FontSize = 16;
% title('Correlation between inputs and outputs');

% overlay numeric correlation values
for i = 1:size(Rpm,1)
    for j = 1:size(Rpm,2)
        val = Rpm(i,j);
        % overlay text
        text(j, i, sprintf('%.2f', val), ...
            'HorizontalAlignment','center', ...
            'FontSize',14);
    end
end

%% Offset and TI relationship
plotMetricRelation(ampgrad, dTIdy_mean);
hold on, scatter(ampgrad, dTIdy_mean, [], defaultOrange, 'filled')
xlabelg('amplitude gradient: $$dA / dy$$ [deg/m]'); ylabelg('turbulence intensity gradient: $$dTI / dy$$');
ax = gca; ax.FontSize = 14;

end





