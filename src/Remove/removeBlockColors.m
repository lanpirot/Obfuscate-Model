function removeBlockColors(blocks)
% REMOVEBLOCKCOLORS Reset the colors of all BLOCKS to the defaults.
    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if ~strcmp(get_param(b, 'ForegroundColor'), 'black')
                set_param(b, 'ForegroundColor', 'black');
            end
            if ~strcmp(get_param(b, 'BackgroundColor'), 'white')
                set_param(b, 'BackgroundColor', 'white');
            end
        catch ME
            smokeLog('skip', 'removeBlockColors', b, ME);
        end
    end
end
