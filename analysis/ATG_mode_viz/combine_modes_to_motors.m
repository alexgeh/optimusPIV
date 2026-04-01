function [phiA_motor, f_motor, theta0_motor, phi0_motor] = ...
    combine_modes_to_motors(Psi, A_modes, phi_modes, phi0_modes, f_common)
% combine_modes_to_motors  Collapse modal params into per-motor sinusoids
%
% Inputs:
%   Psi        : [N x M] mode matrix
%   A_modes    : [M x 1] modal amplitudes (deg)
%   phi_modes  : [M x 1] modal phases (rad)
%   phi0_modes : [M x 1] modal DC offsets (deg)
%   f_common   : common frequency (Hz)
%
% Outputs (per motor):
%   phiA_motor  : amplitude (deg)
%   f_motor     : frequency (Hz)
%   theta0_motor: phase (rad)
%   phi0_motor  : DC offset (deg)

    [N, M] = size(Psi);
    A_modes    = A_modes(:);
    phi_modes  = phi_modes(:);
    phi0_modes = phi0_modes(:);

    % complex phasor sum
    P = zeros(N,1);
    for m = 1:M
        P = P + (A_modes(m) .* Psi(:,m)) .* exp(1i*phi_modes(m));
    end

    phiA_motor   = abs(P);
    theta0_motor = angle(P);
    phi0_motor   = Psi * phi0_modes;
    f_motor      = f_common .* ones(N,1);
end
