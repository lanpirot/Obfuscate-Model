function removeModelReferences(blocks)
% REMOVEMODELREFERENCES Make all Model blocks among BLOCKS point to no model.
    placeholder = '<Enter Model Name>';
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if ~strcmp(get_param(b, 'BlockType'), 'ModelReference')
                continue
            end
            set_param(b, 'ModelNameDialog', placeholder);
        catch ME
            smokeLog('skip', 'removeModelReferences', b, ME);
        end
    end
end
