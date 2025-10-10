function diag = acf_diagnostics(TI_ts, dt, varargin)
% ACF_DIAGNOSTICS  Compute autocorrelation diagnostics for a scalar time series
%
% Usage:
%   diag = acf_diagnostics(TI_ts, dt)
%   diag = acf_diagnostics(TI_ts, dt, 'maxLag', 200, 'c', 5)
%
% Inputs:
%   TI_ts  : [N x 1] scalar time series (e.g., TI per frame)
%   dt     : sampling interval [s] (time between frames)
% Optional name-value:
%   'maxLag' : maximum lag to compute ACF (frames). Default: min( floor(N/2), 2000)
%   'c'      : Sokal window factor for self-consistent truncation (default 5)
%
% Outputs struct diag with fields:
%   .rho        - autocorrelation vector (lags 0..L)
%   .lags       - lag indices (frames)
%   .lags_time  - lag times in seconds
%   .tau_int    - integrated autocorrelation time (frames)
%   .tau_time   - integrated autocorrelation time (s)
%   .N_eff      - effective sample size (approx)
%   .L_block    - recommended block length (frames)
%   .first_neg  - first lag where rho < 0 (if any)
%   .first_1e   - first lag where rho < 1/e
%   .TI_ts      - original series
%
% Also produces plots.

p = inputParser;
addRequired(p,'TI_ts');
addRequired(p,'dt',@isscalar);
addParameter(p,'maxLag',[],@isnumeric);
addParameter(p,'c',5,@(x)isnumeric(x) && x>0);
parse(p,TI_ts,dt,varargin{:});
maxLag = p.Results.maxLag;
c = p.Results.c;

TI_ts = TI_ts(:);
N = numel(TI_ts);

if isempty(maxLag)
    maxLag = min(floor(N/2),2000);
end
maxLag = min(maxLag, N-1);

% Remove linear trend (optional) — detrend helps stationarity
z = detrend(TI_ts,'constant'); % remove mean only; keep slow trends if you prefer

% Compute unbiased autocovariances using xcorr
[acf_full, lags_full] = xcorr(z, maxLag, 'coeff'); % normalized autocorrelation
% xcorr returns lags -maxLag..+maxLag. Keep non-negative lags:
center = find(lags_full==0,1);
rho = acf_full(center:end);    % rho(1) is lag 0 = 1
lags = 0:(length(rho)-1);
lags = lags(:);

% Sokal window (self-consistent truncation)
tau_old = 1;
tau = 1;
M = 1;
while true
    if M > length(rho)-1
        break;
    end
    tau = 1 + 2 * sum(rho(2:M+1)); % rho indices shift: rho(1) is lag 0
    if M > c * tau
        break;
    end
    M = M + 1;
    % avoid infinite loop
    if M > length(rho)-1
        break;
    end
end

% Final truncation index
M_trunc = min(M, length(rho)-1);
tau_int = 1 + 2*sum(rho(2:M_trunc+1));

% Diagnostics
first_neg = find(rho < 0, 1);
first_1e = find(rho < exp(-1), 1);

% Effective sample size
N_eff = N / tau_int;

% Recommended block length in frames (for block bootstrap)
L_block = max(1, ceil(tau_int));  % conservative: at least 1 frame

% Convert to time units
tau_time = tau_int * dt;
lags_time = lags * dt;

% Pack output
diag.rho = rho;
diag.lags = lags;
diag.lags_time = lags_time;
diag.tau_int = tau_int;
diag.tau_time = tau_time;
diag.N = N;
diag.N_eff = N_eff;
diag.L_block = L_block;
diag.first_neg = first_neg;
diag.first_1e = first_1e;
diag.TI_ts = TI_ts;
diag.M_trunc = M_trunc;

% Plots
figure('Name','ACF diagnostics','Position',[100 100 900 600]);
subplot(3,1,1);
plot((0:N-1)*dt, TI_ts, '-k');
xlabel('Time [s]'); ylabel('TI'); title('TI time series');

subplot(3,1,2);
stem(lags_time, rho, 'filled');
hold on;
xline(tau_time,'r--','LineWidth',1.2);
xlabel('Lag [s]'); ylabel('\rho(k)');
title('Autocorrelation (ACF)');
legend('ACF','\tau_{int}');

subplot(3,1,3);
% cumulative tau vs truncation lag
cum_tau = zeros(length(rho)-1,1);
for k=1:length(cum_tau)
    cum_tau(k) = 1 + 2*sum(rho(2:k+1));
end
plot(lags_time(2:end), cum_tau, '-b'); hold on;
xline(lags_time(M_trunc+1),'k--','LineWidth',1.2);
xlabel('Lag [s]'); ylabel('\tau_{int}(k)');
title('Cumulative integrated autocorrelation time vs lag');
legend('cumulative \tau','truncation');

% summary text
sgtitle(sprintf('ACF diagnostics: N=%d, \\tau_{int}=%.2f frames (%.2fs), N_{eff}=%.1f', ...
    N, tau_int, tau_time, N_eff));

% Print a brief table in command window
fprintf('ACF diagnostics:\n');
fprintf('  N frames = %d\n', N);
fprintf('  tau_int = %.3f frames (%.3f s)\n', tau_int, tau_time);
fprintf('  recommended block length (frames) ~ %d\n', L_block);
fprintf('  effective sample size N_eff ~ %.1f\n', N_eff);
if ~isempty(first_1e)
    fprintf('  first lag where rho<1/e: %d frames (%.3f s)\n', first_1e-1, (first_1e-1)*dt);
end
if ~isempty(first_neg)
    fprintf('  first lag where rho<0: %d frames (%.3f s)\n', first_neg-1, (first_neg-1)*dt);
end

end
