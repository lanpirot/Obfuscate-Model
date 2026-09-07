function removeSignalNames(lines, blocks)
% REMOVESIGNALNAMES Clear the names of all LINES, and switch off signal label
% propagation on the output ports of all BLOCKS.
% Note: names of bus element signals cannot be cleared this way.

    for i = 1:numel(lines)
        l = lines(i);
        try
            if ~isempty(get_param(l, 'Name'))
                set_param(l, 'Name', '');
            end
        catch ME
            smokeLog('skip', 'removeSignalNames', l, ME);
        end
    end

    for i = 1:numel(blocks)
        b = blocks(i);
        try
            outports = get_param(b, 'PortHandles').Outport;
        catch
            continue
        end
        for k = 1:numel(outports)
            try
                if strcmp(get_param(outports(k), 'ShowPropagatedSignals'), 'on')
                    set_param(outports(k), 'ShowPropagatedSignals', 'off')
                end
            catch ME
                smokeLog('skip', 'removeSignalNames', b, ME, sprintf('outport %d', k));
            end
        end
    end
end
