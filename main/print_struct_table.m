function print_struct_table(s, title_str, indent)
%PRINT_STRUCT_TABLE Nicely prints a struct as a table with auto formatting.
% Supports nested structs.
%
%   s: Struct with parameters
%   title_str: (optional) title to display before the table
%   indent: (internal use) string indentation for nested structs

    if nargin < 3
        indent = '';
    end

    if nargin >= 2 && ~isempty(title_str)
        fprintf('\n%s%s\n', indent, title_str);
    end

    fprintf('%s--------------------------------------------------\n', indent);
    fields = fieldnames(s);
    for i = 1:numel(fields)
        name = fields{i};
        value = s.(name);

        % Format label
        label = regexprep(name, '_', ' ');
        label = [upper(label(1)), label(2:end)];

        % Handle nested structs recursively
        if isstruct(value)
            fprintf('%s%-25s : [struct]\n', indent, label);
            print_struct_table(value, '', [indent '  ']); % recursive call with indent
            continue;
        end

        % Convert value to printable string
        if isnumeric(value)
            valStr = num2str(value);
        elseif islogical(value)
            valStr = mat2str(value);
        elseif ischar(value)
            valStr = value;
        elseif isstring(value)
            valStr = char(value);
        else
            valStr = '<unsupported type>';
        end

        fprintf('%s%-25s : %s\n', indent, label, valStr);
    end
    fprintf('%s--------------------------------------------------\n', indent);
end
