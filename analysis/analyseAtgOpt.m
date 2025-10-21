%% Script to analyze ATG PIV optimization
%#ok<*SAGROW> 
clear

projDir = "R:\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\fullOptimizations\20251017_ATG_bayes_opt_3\";
pivFolder = fullfile(projDir, "proc_PIV");
plotDir = "R:\ENG_Breuer_Shared\agehrke\PLOTS\2025_optimusPIV\20251017_ATG_bayes_opt_3";

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
    J_hom_velgrad(iter) = optResults(iter).J_comp.J_hom_velgrad;
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
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "U", "U_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.U;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'U';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Crossstream Velocity Field
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "V", "V_" + mpt2str(iter) + ".png");
    toplot = optResults(iter).fields.V;
    limits = [mean(toplot(:))-2*std(toplot(:)) mean(toplot(:))+2*std(toplot(:))];
    nLevel = 40;
    [C,h] = contourf(toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    a=colorbar;
    a.Label.String = 'V';
    clim(limits)
    export_fig(fname, '-png', '-opengl','-r600');
end


%% Average Turbulence Intensity Field
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "TI", "TI_" + mpt2str(iter) + ".png");
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
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "aniso", "aniso_" + mpt2str(iter) + ".png");
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
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "velgrad", "velgrad_" + mpt2str(iter) + ".png");
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
figure()
for iter = 1:nIter
    fname = fullfile(plotDir, "flowFields", "TIgrad", "TIgrad_" + mpt2str(iter) + ".png");
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TIME RESOLVED PLOTS:
for iter = [23,28]%5:nIter
    folder = fullfile(pivFolder, sprintf('ms%.4d', iter));
    D = loadpiv(folder);
    x = D.x; y = D.y;
    u = D.u; v = D.v;
    nFrames = size(u,3);
    vort = D.vort;
%     u(isnan(u)) = 0;
%     v(isnan(v)) = 0;
    
    xRange = [-0.1445 0.0667]; % Was required for 20251017_ATG_bayes_opt_3 - cam1
    yRange = [-0.0650 0.1396];
    
    [x_crop,y_crop,u_crop,v_crop,vort_crop] = cropFields(xRange,yRange,x,y,u,v,vort);
    
    %% Streamwise Velocity Field
    targetFolder = fullfile(plotDir, "flowfields", "u_timeres", sprintf('ms%.4d', iter));
    ensureTopLevelFolder(targetFolder);
    figure()
    for iFrame = 1:nFrames
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
    figure()
    for iFrame = 1:nFrames
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
    figure()
    for iFrame = 1:nFrames
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

