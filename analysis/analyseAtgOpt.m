%% Script to analyze ATG PIV optimization
%#ok<*SAGROW> 
clear

optID = 6;
switch optID
    case 3 % Synchronous ATG control - TI_target = 0.2, homogenous, isotropic
        projStr = "20251017_ATG_bayes_opt_3";
        xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
        yRange = [-0.0650 0.1396];
        nPlotFrames = 200;
    % Cases 4,5,6:
    % Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient
    case 4 % !! LAST 10 PIV FRAMES FAULTY !! -> optim. not usable
        projStr = "20251022_ATG_bayes_opt_4";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190; % LAST 10 FRAMES NOT ILLUMINATED
    case 5 % !! DID NOT CONVERGE !! -> optim. not usable
        projStr = "20251022_ATG_bayes_opt_4";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    case 6 % succesful run of "Gradient ATG control - TI_target = 0.2, dudy = -2.5, min TI gradient"
        projStr = "20251023_ATG_bayes_opt_6";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    case 7 % Gradient ATG control - TI_target = 0.2, dTIdy = -0.2, min vel gradient
        projStr = "20251024_ATG_bayes_opt_7";
        xRange = [-0.1445 0.0667]; % higher aspect ratio for 20251022 (higher y for better y-gradient resolution)
        yRange = [-0.111 0.137];
        nPlotFrames = 190;
    otherwise
        error('opt ID not found - cannot continue')
end

projDir = fullfile("R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\", projStr);
plotDir = fullfile("R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\", projStr);
pivFolder = fullfile(projDir, "proc_PIV");
load(fullfile(projDir, "workspaceOptimization.mat"))

variousColorMaps();

J = [optResults.J];
freq = [optResults.freq];
alpha = [optResults.alpha];
relBeta = [optResults.relBeta];
ampl = [optResults.ampl];
offset = [optResults.offset];

nIter = length(J);

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


%% Plot all flow fields:
%% Average Streamwise Velocity Field
targetFolder = fullfile(plotDir, "flowfields", "U");
ensureTopLevelFolder(targetFolder);
figure(501)
for iter = 1:nIter
    fname = fullfile(targetFolder, "U_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.U;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    colormap('jet')
    a=colorbar;
    a.Label.String = 'U';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
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

for iter = 1:nIter
    folder = fullfile(pivFolder, sprintf('ms%.4d', iter));
    D = loadpiv(folder);
    x = D.x; y = D.y;
    u = D.u; v = D.v;
    nFrames = size(u,3);
    vort = D.vort;
%     u(isnan(u)) = 0;
%     v(isnan(v)) = 0;
    
    [x_crop,y_crop,u_crop,v_crop,vort_crop] = cropFields(xRange,yRange,x,y,u,v,vort);
    
    %% Streamwise Velocity Field
    targetFolder = fullfile(plotDir, "flowfields", "u_timeres", sprintf('ms%.4d', iter));
    ensureTopLevelFolder(targetFolder);
    figure(507)
    for iFrame = 1:nPlotFrames
        fname = fullfile(targetFolder, "u_" + mpt2str(iFrame) + ".png");
        toplot = u_crop(:,:,iFrame);
        limits = [mean(u_crop(:))-2*std(u_crop(:)) mean(u_crop(:))+2*std(u_crop(:))];
        nLevel = 100;
        [C,h] = contourf(x_crop, y_crop, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
        set(h,'linestyle','none')
        colormap('jet')
        a=colorbar;
        a.Label.String = 'u';
        clim(limits)
        export_fig(fname, '-png', '-opengl','-r600');
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
%     


%% Display best / worst
[bestJ,ibest] = min(J);
[worstJ,iworst] = max(J);
fprintf('Best trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
ibest, freq(ibest), ampl(ibest), offset(ibest), J(ibest), TI_mean(ibest));
fprintf('Worst trial #%d: f=%.3f A=%.3f theta=%.3f J=%.4f TI=%.3f\n', ...
iworst, freq(iworst), ampl(iworst), offset(iworst), J(iworst), TI_mean(iworst));


%% Plotting of metrics
yRangeArray = linspace(0,yRange(2)-yRange(1),length(toplot));
yHeight = yRange(2)-yRange(1);

% U
toplot = mean(optResults(8).fields.U,2);
figure(); hold on;
plot(yRangeArray, toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
% plot(yRange-yRange(1), 0*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$U$$");

% dU_dy
toplot = mean(optResults(8).fields.dUdy,2);
figure(); hold on;
plot(yRangeArray, toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], 0*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$dU/dy$$");

% TI
toplot = mean(optResults(8).fields.TI,2);
dTIdy_mean = mean(optResults(8).fields.dTIdy,'all');
dTIdy_Delta = dTIdy_mean*yHeight/2;

figure(); hold on;
plot(yRangeArray, toplot);
% plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], [mean(toplot)-dTIdy_Delta, mean(toplot)+dTIdy_Delta]);
xlabelg("$$y [m]$$"); ylabelg("$$TI$$");

% dTI_dy
toplot = mean(optResults(8).fields.dTIdy,2);
figure(); hold on;
plot(linspace(0,yRange(2)-yRange(1),length(toplot)), toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], -0.2*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$dTI/dy$$");


%% best case 6
yRangeArray = linspace(0,yRange(2)-yRange(1),length(toplot));
yHeight = yRange(2)-yRange(1);

% U
toplot = mean(optResults(ibest).fields.U,2);
dUdy_mean = mean(optResults(ibest).fields.dUdy,'all');
dUdy_Delta = dUdy_mean*yHeight/2;

figure(); hold on;
plot(yRangeArray, toplot);
% plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], [mean(toplot)-dUdy_Delta, mean(toplot)+dUdy_Delta]);
% plot(yRange-yRange(1), 0*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$U$$");

% dU_dy
toplot = mean(optResults(ibest).fields.dUdy,2);
figure(); hold on;
plot(yRangeArray, toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], -2.5*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$dU/dy$$");

% TI
toplot = mean(optResults(ibest).fields.TI,2);
dTIdy_mean = mean(optResults(8).fields.dTIdy,'all');
dTIdy_Delta = dTIdy_mean*yHeight/2;

figure(); hold on;
plot(yRangeArray, toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
% plot([0 yHeight], [mean(toplot)-dTIdy_Delta, mean(toplot)+dTIdy_Delta]);
xlabelg("$$y [m]$$"); ylabelg("$$TI$$");

% dTI_dy
toplot = mean(optResults(ibest).fields.dTIdy,2);
figure(); hold on;
plot(linspace(0,yRange(2)-yRange(1),length(toplot)), toplot);
plot([0 yHeight], mean(toplot)*ones(2,1));
plot([0 yHeight], 0*ones(2,1), 'Color', 'black');
xlabelg("$$y [m]$$"); ylabelg("$$dTI/dy$$");

