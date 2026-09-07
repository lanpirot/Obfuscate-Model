function removeMasks(blocks)
% REMOVEMASKS Delete the masks of all masked BLOCKS, including mask code,
% mask parameters, and mask icons.
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if ~strcmp(get_param(b, 'Mask'), 'on')
                continue
            end
            m = Simulink.Mask.get(b);
            if ~isempty(m)
                m.delete();
            end
        catch ME
            smokeLog('skip', 'removeMasks', b, ME);
        end
    end
end
