function XN = actLearn_normalizeInputs(X, input_defs, doClip)
%% Normalize active-learning input coordinates to [0, 1].
%
% Inputs
%   X          : n x d matrix or 1 x d vector in physical/design coordinates
%   input_defs : active input definitions, each with .range = [min max]
%   doClip     : optional logical. If true, clip values to [0, 1].
%
% Output
%   XN         : n x d matrix in normalized coordinates
%
% Notes
%   This function should be used everywhere the GP model coordinates are
%   needed:
%       - before GP training
%       - before GP prediction
%       - before nearest-neighbour distance calculations
%
%   The experiment itself should still receive the physical/design values.

    if nargin < 3
        doClip = false;
    end

    nInputs = numel(input_defs);

    if isempty(X)
        XN = zeros(0, nInputs);
        return
    end

    if isvector(X)
        X = X(:)';
    end

    if size(X,2) ~= nInputs
        error('actLearn_normalizeInputs:DimensionMismatch', ...
            'X has %d columns, but input_defs has %d entries.', ...
            size(X,2), nInputs);
    end

    XN = NaN(size(X));

    for k = 1:nInputs
        bounds = input_defs(k).range;
        denom = bounds(2) - bounds(1);

        if ~isfinite(denom) || denom <= 0
            error('actLearn_normalizeInputs:InvalidRange', ...
                'Invalid range for input %s.', input_defs(k).name);
        end

        XN(:,k) = (X(:,k) - bounds(1)) ./ denom;
    end

    if doClip
        XN = max(0, min(1, XN));
    end
end
