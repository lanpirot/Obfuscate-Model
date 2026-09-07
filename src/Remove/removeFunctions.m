function removeFunctions(blocks)
% REMOVEFUNCTIONS Remove the code of all MATLAB Function blocks among BLOCKS.
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if ~strcmp(get_param(b, 'SFBlockType'), 'MATLAB Function')
                continue
            end
        catch
            continue % not a Stateflow based block
        end
        try
            config = get_param(b, 'MATLABFunctionConfiguration');
            config.FunctionScript = '0';
        catch ME
            smokeLog('skip', 'removeFunctions', b, ME);
        end
    end
end
