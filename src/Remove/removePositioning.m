function removePositioning(blocks, systems)
% REMOVEPOSITIONING Forget the layout of all BLOCKS and let Simulink arrange
% each of the SYSTEMS anew. Each call may give a different diagram.
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            pos = get_param(b, 'Position');
            set_param(b, 'Position', [0 0 pos(3) - pos(1) pos(4) - pos(2)])
        catch ME
            smokeLog('skip', 'removePositioning', b, ME);
        end
    end

    for i = 1:numel(systems)
        try
            Simulink.BlockDiagram.arrangeSystem(systems(i), 'FullLayout', 'true')
        catch ME
            smokeLog('skip', 'removePositioning', systems(i), ME, 'arrangeSystem');
        end
    end
end
