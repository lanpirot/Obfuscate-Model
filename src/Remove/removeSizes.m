function removeSizes(blocks)
% REMOVESIZES Reset the size of all BLOCKS to the default size of their block
% type (read from a pristine block, see defaultBlock). Positions are kept.
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            ref = defaultBlock(get_param(b, 'BlockType'));
            if ref < 0
                smokeLog('skip', 'removeSizes', b, 'Simulink cannot create a default block of this type');
                continue
            end
            refPos = get_param(ref, 'Position');
            pos = get_param(b, 'Position');
            newPos = [pos(1) pos(2) pos(1) + refPos(3) - refPos(1) pos(2) + refPos(4) - refPos(2)];
            if ~isequal(pos, newPos)
                set_param(b, 'Position', newPos)
            end
        catch ME
            smokeLog('skip', 'removeSizes', b, ME);
        end
    end
end
