function field_clean = fill_piv_nan(field_in, window_size)
    % field_in: 3D matrix (Y, X, Frames)
    % window_size: Size of the 2D spatial neighborhood (e.g., 5 for a 5x5 area)
    
    field_clean = field_in;
    
    % Find all NaN locations across the entire 3D stack instantly
    nan_indices = find(isnan(field_in));
    
    % If there are no NaNs, exit early
    if isempty(nan_indices)
        return;
    end
    
    [rows, cols, frames] = ind2sub(size(field_in), nan_indices);
    
    half_w = floor(window_size / 2);
    [max_r, max_c, ~] = size(field_in); % Third dimension size isn't needed for boundaries

    % Iterate ONLY over the NaNs, not the frames
    for k = 1:length(rows)
        r = rows(k);
        c = cols(k);
        f = frames(k); % Identify which frame this NaN belongs to

        % Define 2D spatial boundaries with edge protection
        r_start = max(1, r - half_w);
        r_end   = min(max_r, r + half_w);
        c_start = max(1, c - half_w);
        c_end   = min(max_c, c + half_w);

        % Extract the 2D neighborhood strictly from the current frame 'f'
        neighborhood = field_in(r_start:r_end, c_start:c_end, f);

        % Calculate median of non-NaN values
        valid_vals = neighborhood(~isnan(neighborhood));

        if ~isempty(valid_vals)
            field_clean(r, c, f) = median(valid_vals);
        else
            warning('NaN at (Y:%d, X:%d, Frame:%d) could not be filled.', r, c, f);
        end
    end
end
