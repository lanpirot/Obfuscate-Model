function removeImplementation(sys)
% REMOVEIMPLEMENTATION Delete every block and line directly inside SYS, except
% the interface blocks (Inport, Outport, TriggerPort, EnablePort, ActionPort,
% ResetPort). Nested subsystems are deleted with their whole content.

    common = {'SearchDepth', 1, 'LookUnderMasks', 'all', 'MatchFilter', @Simulink.match.allVariants, 'FindAll', 'on'};
    sys = get_param(sys, 'Handle');

    lines = find_system(sys, common{:}, 'Type', 'line');
    for i = 1:numel(lines)
        try
            delete_line(lines(i));
        catch ME
            smokeLog('skip', 'removeImplementation', lines(i), ME);
        end
    end

    blocks = find_system(sys, common{:}, 'Type', 'block');
    blocks = blocks(blocks ~= sys);
    keep = {'Inport', 'Outport', 'TriggerPort', 'EnablePort', 'ActionPort', 'ResetPort'};
    for i = 1:numel(blocks)
        try
            if ismember(get_param(blocks(i), 'BlockType'), keep)
                continue
            end
            delete_block(blocks(i));
        catch ME
            smokeLog('skip', 'removeImplementation', blocks(i), ME);
        end
    end
end
