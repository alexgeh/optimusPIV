%% Plot Optimus PIV Results (20250814 - Alex, Evan - Wind Tunnel)
%
%  20250817 - Alexander Gehrke

clear

% rootDir = "\\Files22.brown.edu\LRSResearch\ENG_Breuer_Shared\agehrke\DATA\2025_optimusPIV\20250814_bayes_opt_2\";
rootDir = "C:\Users\alexg\OneDrive\Documents\MATLAB\localOptPIV\";
workspaceFile = fullfile(rootDir, "workspaceOptimization_twoParam.mat");
pivDataDir = fullfile(rootDir, "proc_PIV");
plotDir = fullfile(rootDir, "plots");

load(workspaceFile)

savePlots = false;


%% Turbine and case parameters
Uinf = 4; % Free-stream velocity
c = 0.105; % Wing chord


%% Plot Bayesian Opt Model
freq = [optResults.freq].';
pitchA = [optResults.pitchA].';
C_T = [optResults.C_T].';

figure;
for mpti = 1:length(C_T)
    clf(); hold on;

    % plotBayOpt2D(pitchA(1:mpti), -C_T(1:mpti)) % For 2d
    plotBayOpt3D([freq(1:mpti), pitchA(1:mpti)], -C_T(1:mpti))

    % xlim([0, 70]); ylim([-0.0500, 0.3000]); % For 2d
    xlim([0, 8]); ylim([0, 60]); zlim([-40, 40]); % For 3d
    xlabel("frequency f [Hz]"); ylabel("amplitude \theta_A [deg]");
    zlabel("-C_T")

    view([46 -36])
    
    if savePlots
        fname = sprintf("surrogateModel_%.5d.png", mpti);
        set(gcf, 'Color', 'w');
        export_fig(fullfile(plotDir, "surrogateModel_twoParam", fname), '-png', '-r600');
    else
        pause(0.1)
    end
end

