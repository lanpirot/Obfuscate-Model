function removeCustomDataTypes(inports)
% REMOVECUSTOMDATATYPES Reset the output data type of INPORTS to 'Inherit: auto'.
% Custom data types often reveal bus objects and enumerations by name.
    for i = 1:numel(inports)
        b = inports(i);
        try
            if ~strcmp(get_param(b, 'OutDataTypeStr'), 'Inherit: auto')
                set_param(b, 'OutDataTypeStr', 'Inherit: auto');
            end
        catch ME
            smokeLog('skip', 'removeCustomDataTypes', b, ME);
        end
    end
end
