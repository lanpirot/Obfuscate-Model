function removeCustomDataTypes(blocks)
% REMOVECUSTOMDATATYPES Reset custom output data types (bus objects,
% enumerations, aliases) of all BLOCKS to 'Inherit: auto', or to 'double'
% where inheritance is not allowed. Built-in and fixed-point types are kept.
    builtin = {'double', 'single', 'half', 'boolean', 'string', ...
        'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'};
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            t = strtrim(get_param(b, 'OutDataTypeStr'));
        catch
            continue % block has no output data type
        end
        if isempty(t) || startsWith(t, 'Inherit') || ismember(t, builtin) || ~isempty(regexp(t, '^(fixdt|[su]fix|flt[su])', 'once'))
            continue
        end
        try
            set_param(b, 'OutDataTypeStr', 'Inherit: auto');
        catch
            try
                set_param(b, 'OutDataTypeStr', 'double');
            catch ME
                smokeLog('skip', 'removeCustomDataTypes', b, ME, t);
            end
        end
    end
end
