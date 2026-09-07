function h = defaultBlock(blockType)
% DEFAULTBLOCK Return a pristine block of BLOCKTYPE to read default values from.
%
%   Simulink offers no way to ask for a block's default parameter values or
%   default size. SMOKE therefore creates one untouched block per block type in
%   a hidden scratch model and reads the defaults from it. Blocks are created
%   once per SMOKE run and cached.
%
%   h = defaultBlock(type)   handle of the pristine block, or -1 when Simulink
%                            cannot create the type via 'built-in/<type>'
%   defaultBlock('-clear')   close the scratch model and empty the cache

    persistent cache
    scratch = 'SMOKE_scratch_defaults';

    if strcmp(blockType, '-clear')
        cache = [];
        if bdIsLoaded(scratch)
            close_system(scratch, 0);
        end
        h = -1;
        return
    end

    if ~bdIsLoaded(scratch)
        new_system(scratch);
        cache = [];
    end
    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end

    if isKey(cache, blockType)
        h = cache(blockType);
        return
    end
    try
        h = add_block(['built-in/' blockType], [scratch '/' blockType], 'MakeNameUnique', 'on');
    catch
        h = -1;
    end
    cache(blockType) = h;
end
