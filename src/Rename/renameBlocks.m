function renameBlocks(blocks)
% RENAMEBLOCKS Rename all BLOCKS to '<block type><number>' and hide the names.

    if isempty(blocks)
        return
    end
    types = get_param(blocks, 'BlockType');
    if ~iscell(types)
        types = {types};
    end
    for h = 1:numel(blocks)
        if ~strcmp(types{h}, 'SubSystem')
            continue
        end
        try
            sfBlockType = get_param(blocks(h), 'SFBlockType');
        catch
            sfBlockType = '';
        end
        if ~isempty(sfBlockType) && ~strcmpi(sfBlockType, 'NONE')
            types{h} = strrep(sfBlockType, ' ', '');
        else
            try
                types{h} = getSubsystemType(blocks(h));
            catch
                types{h} = 'Subsystem';
            end
        end
    end

    suffix = 1;
    for j = 1:numel(blocks)
        b = blocks(j);
        for attempt = 1:50
            suffix = suffix + 1;
            try
                set_param(b, 'Name', [types{j} num2str(suffix)]);
                set_param(b, 'ShowName', 'off');
                break
            catch ME
                clash = contains(lower(ME.message), {'exist', 'unique', 'already', 'in use', 'duplicate'});
                if ~clash || attempt == 50
                    smokeLog('skip', 'renameBlocks', b, ME);
                    break
                end
            end
        end
    end
end
