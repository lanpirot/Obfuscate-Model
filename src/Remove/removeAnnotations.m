function removeAnnotations(annotations, blocks)
% REMOVEANNOTATIONS Delete all text, area, and image ANNOTATIONS, and clear the
% block annotations (AttributesFormatString) of all BLOCKS.
    for i = 1:numel(annotations)
        try
            delete(annotations(i))
        catch ME
            smokeLog('skip', 'removeAnnotations', annotations(i), ME);
        end
    end

    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if ~isempty(get_param(b, 'AttributesFormatString'))
                set_param(b, 'AttributesFormatString', '');
            end
        catch ME
            smokeLog('skip', 'removeAnnotations', b, ME, 'AttributesFormatString');
        end
    end
end
