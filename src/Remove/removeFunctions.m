function removeFunctions(blocks)
% REMOVEFUNCTIONS Replace the code of all MATLAB Function blocks among BLOCKS
% by a stub with the same inputs and outputs that sets every output to -17.
% The model stays compilable; the implementation is gone.
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
            config.FunctionScript = stub(b);
        catch ME
            smokeLog('skip', 'removeFunctions', b, ME);
        end
    end
end

function script = stub(block)
    ins = {};
    outs = {};
    chart = sfroot().find('-isa', 'Stateflow.EMChart', 'Path', getfullname(block));
    if ~isempty(chart)
        ins = portNames(chart(1), 'Input');
        outs = portNames(chart(1), 'Output');
    end
    if isempty(outs)
        head = 'function fcn';
    elseif isscalar(outs)
        head = ['function ' outs{1} ' = fcn'];
    else
        head = ['function [' strjoin(outs, ', ') '] = fcn'];
    end
    body = cellfun(@(o) sprintf('%s = -17;', o), outs, 'UniformOutput', false);
    script = sprintf('%s(%s)\n%s', head, strjoin(ins, ', '), strjoin(body, newline));
end

function names = portNames(chart, scope)
    data = chart.find('-isa', 'Stateflow.Data', 'Scope', scope);
    [~, order] = sort(arrayfun(@(d) d.Port, data));
    names = arrayfun(@(d) d.Name, data(order), 'UniformOutput', false);
    names = names(:)';
end
