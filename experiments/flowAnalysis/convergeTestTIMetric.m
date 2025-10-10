%% Script to test convergence of TI metrics with increasing nFrames
clear

PIVfolder = 'R:\ENG_Breuer_Shared\group\ATG\ATG_PIV\Wind_Turbine_20250609\ATG_250822_002\StereoPIV_MPd(2x32x32_75%ov)_GPU';
% PIVfolder = 'R:\ENG_Breuer_Shared\group\ATG\ATG_PIV\Wind_Turbine_20250609\ATG_250822_005\StereoPIV_MPd(2x32x32_75%ov)';
maxFrames = 5000; % maximum number to read once
sampleSizes = [50, 100, 200, 500, 1000, 2000, 3000, 4000, 5000]; % test cases
% sampleSizes = [50, 100, 200, 500, 1000, 2000, 2561]; % test cases
targetTI = 0.2;

% Load maximum dataset once
fprintf('Reading %d frames... this may take a while.\n', maxFrames);
% [uAll, vAll, ~, x, y] = readVC7Folder(PIVfolder, maxFrames);
% x = x(:,:,1); y = y(:,:,1);

D = loadpiv(PIVfolder);
x = D.x; y = D.y;
u = D.u; v = D.v;
vort = D.vort;
u(isnan(u)) = 0;
v(isnan(v)) = 0;

% dt = mean(diff(D.AcqTime)) / 10^6; % Convert micro seconds to seconds
dt = 1 / 720; % acqFreq ~ 720Hz

xRange = [-0.1949 -0.0086];
yRange = [0.1175 -0.0715];
[x_crop,y_crop,u_crop,v_crop] = cropFields(xRange,yRange,x,y,u,v);


%% Calculate turbulence metrics
% Preallocate
nSamples = numel(sampleSizes);
TI_mean = zeros(1,nSamples);
Homogeneity = zeros(1,nSamples);
Anisotropy = zeros(1,nSamples);

for k = 1:numel(sampleSizes)
    n = sampleSizes(k);

    % Pick n frames spread across full range
    idx = round(linspace(1,maxFrames,n));
%     u_single = u(:,:,idx);
%     v_single = v(:,:,idx);
    u_range = u_crop(:,:,idx);
    v_range = v_crop(:,:,idx);

%     [~, metrics] = turbulenceIntensityMetric(u_single,v_single,x_crop,y_crop,false);
    [metrics, fields] = turbulenceMetrics(u_range,v_range,x_crop,y_crop,false);
%     pause(0.2)

    TI_mean(k) = metrics.TI_mean;
    Homogeneity(k) = metrics.CV;
    Anisotropy(k) = metrics.aniso_mean;
end


%% Plot convergence
figure;
subplot(3,2,1);
plot(sampleSizes, TI_mean, '-o');
xlabel('Number of frames'); ylabel('TI mean');

subplot(3,2,3);
plot(sampleSizes, Homogeneity, '-o');
xlabel('Number of frames'); ylabel('Homogeneity');

subplot(3,2,5);
plot(sampleSizes, Anisotropy, '-o');
xlabel('Number of frames'); ylabel('Anisotropy');

subplot(3,2,2);
plot(sampleSizes, TI_mean/TI_mean(end), '-o');
xlabel('Number of frames'); ylabel('rel. TI mean');

subplot(3,2,4);
plot(sampleSizes, Homogeneity/Homogeneity(end), '-o');
xlabel('Number of frames'); ylabel('rel. Homogeneity');

subplot(3,2,6);
plot(sampleSizes, Anisotropy/Anisotropy(end), '-o');
xlabel('Number of frames'); ylabel('rel. Anisotropy');

sgtitle('Frame convergence test');


%% Estimate frame rate needed for proper statistics
% Example: compute TI time series (spatial mean TI per frame)
Nframes = size(u,3);
TI_ts = nan(Nframes,1);
umean = mean(u,3); vmean = mean(v,3);
for k = 1:Nframes
    % u(:,:,k), v(:,:,k) are instantaneous fields
    % compute instantaneous deviation from temporal mean? Better to compute
    % TI as RMS over a sliding window, but simplest is to compute spatial rms
    % using ensemble? If you already have TI per-frame from your pipeline, use it.
    % Here we compute instantaneous velocity magnitude fluctuation relative to
    % long-term mean field (precomputed Umean):
    % (assuming Umean computed over all frames earlier)
    urms_frame = sqrt( (u(:,:,k)-umean).^2 );
    vrms_frame = sqrt( (v(:,:,k)-vmean).^2 );
    TI_field_frame(:,:,k) = sqrt(0.5*(urms_frame.^2 + vrms_frame.^2)) ./ (sqrt(umean.^2+vmean.^2) + eps);
    TI_ts(k) = mean(TI_field_frame(:,:,k),'all','omitnan');
end


diag = acf_diagnostics(TI_ts, dt);


%% Plot of time-resolved velocity field
figure()
limits = [0.75*mean(u,'all','omitnan') 1.25*mean(u,'all','omitnan')];
nLevel = 50;
for framei = 1:n
    toplot = u(:,:,framei);
    [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    colorbar()
    clim(limits)
    title("velocity field, frame: " + num2str(framei))
    pause(0.1)
end

%% Plot of time-resolved vorticity field
figure()
% limits = [-125 125];
limits = [-50 50];
nLevel = 25;
for framei = 1:n
    toplot = vort(:,:,framei);
    [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    colorbar()
    clim(limits)
    title("velocity field, frame: " + num2str(framei))
    pause(0.1)
end

%% Plot of time-resolved TI
figure()
limits = [0.75*TI_mean(end) 1.25*TI_mean(end)];
nLevel = 25;
for framei = 1:n
    toplot = TI_field_frame(:,:,framei);
    [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    colorbar()
    clim(limits)
    title('Turbulence intensity field')
    pause(0.1)
end


