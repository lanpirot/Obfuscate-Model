function renameShared(blocks, param, prefix, blockTypes, startSys, rule)
% RENAMESHARED Rename a name-valued PARAM that connects several BLOCKS
% (Goto tags, data store names) to '<prefix><n>', one number per distinct
% name. Names that also occur on blocks of BLOCKTYPES outside the scope are
% kept, and new names never collide with names used outside the scope.

    if isempty(blocks)
        return
    end
    names = get_param(blocks, param);
    if ~iscell(names)
        names = {names};
    end

    % names used outside the scope
    outside = [];
    model = get_param(bdroot(startSys), 'Handle');
    for t = 1:numel(blockTypes)
        found = find_system(model, 'LookUnderMasks', 'all', 'MatchFilter', @Simulink.match.allVariants, 'BlockType', blockTypes{t});
        outside = [outside; found(:)]; %#ok<AGROW>
    end
    outside = setdiff(outside, blocks);
    outsideNames = {};
    if ~isempty(outside)
        outsideNames = get_param(outside, param);
        if ~iscell(outsideNames)
            outsideNames = {outsideNames};
        end
    end

    distinct = unique(names);
    next = 0;
    for k = 1:numel(distinct)
        old = distinct{k};
        if ismember(old, outsideNames)
            smokeLog('note', rule, startSys, ['name ''' old ''' is also used outside the scope and was kept']);
            continue
        end
        next = next + 1;
        new = sprintf('%s%d', prefix, next);
        while ismember(new, outsideNames)
            next = next + 1;
            new = sprintf('%s%d', prefix, next);
        end
        members = blocks(strcmp(names, old));
        for m = 1:numel(members)
            try
                set_param(members(m), param, new);
            catch ME
                smokeLog('skip', rule, members(m), ME);
            end
        end
    end
end
