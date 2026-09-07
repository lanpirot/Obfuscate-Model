function renameConstants(blocks)
% RENAMECONSTANTS Reset the value of all Constant BLOCKS. Numbers, variables,
% and expressions become -17, string constants "-17". If a constant already
% is -17, it becomes -19: the value must change (see neutralValue).
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            value = get_param(b, 'Value');
            set_param(b, 'Value', neutralValue(value));
        catch ME
            smokeLog('skip', 'renameConstants', b, ME);
        end
    end
end
