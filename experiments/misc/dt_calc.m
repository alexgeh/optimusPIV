
% scaling_factor = 11.35; % px/mm (f = 60mm)
% scaling_factor = 11.09; % px/mm (f = 50mm)
scaling_factor = 7.36; % px/mm (f = 50mm) - 20251009

% U = 8.79; % m/s 200 RPM
U = 5; % m/s

d_px = 6; % px target pixel displacement

dt_sec =  d_px  /  (scaling_factor * 1000) / U;

dt_usec = dt_sec * 10^6
