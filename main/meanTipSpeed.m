function mean_speed = meanTipSpeed(c, A, f)
%MEANTIPVELO Summary of this function goes here
%   Detailed explanation goes here

% mean_speed = abs(c*A*sin(2*pi^2*f) / pi);
mean_speed = 4 * c * A * f / pi;
end

