function Psi = defineModes(nVert, nHoriz)
% defineModes  Physics-informed mode shapes for motor array
%   nVert  : number of vertical motors (per column)
%   nHoriz : number of horizontal motors (per row)
% Returns:
%   Psi    : [N x M] mode matrix, each column is one mode
%
% Modes:
%   1: Global in-phase (all +1)
%   2: Opposite vertical vs horizontal
%   3: Vertical gradient (top vs bottom)
%   4: Horizontal gradient (left vs right)

    N = nVert + nHoriz;
    Psi = zeros(N,4);

    % Mode 1: all +1
    Psi(:,1) = ones(N,1);

    % Mode 2: vertical vs horizontal opposite
    Psi(1:nVert,2) =  1;     % vertical motors
    Psi(nVert+1:end,2) = -1; % horizontal motors

    % Mode 3: vertical gradient (top to bottom)
    Psi(1:nVert,3) = linspace(-1,1,nVert)'; 
    % horizontals zero

    % Mode 4: horizontal gradient (left to right)
    Psi(nVert+1:end,4) = linspace(-1,1,nHoriz)'; 
    % verticals zero
end
