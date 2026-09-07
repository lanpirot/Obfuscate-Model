function recurseModelReferences(refBlocks, options)
% RECURSEMODELREFERENCES Apply SMOKE with OPTIONS to every model referenced by
% the Model blocks REFBLOCKS. Each referenced model is transformed once, in
% memory, and left open and unsaved: the user decides whether to save it
% (save_system(..., 'SaveDirtyReferencedModels', 'on') saves all at once).
%
%   recurseModelReferences('-reset') forgets which models were visited.

    persistent visited
    if ischar(refBlocks) && strcmp(refBlocks, '-reset')
        visited = {};
        return
    end
    if isempty(visited)
        visited = {};
    end

    for i = 1:numel(refBlocks)
        b = refBlocks(i);
        try
            if strcmp(get_param(b, 'ProtectedModel'), 'on')
                smokeLog('note', 'recurseModelReferences', b, 'protected model, cannot be transformed');
                continue
            end
        catch
        end
        try
            name = get_param(b, 'ModelName');
        catch ME
            smokeLog('skip', 'recurseModelReferences', b, ME);
            continue
        end
        if isempty(name) || ismember(name, visited)
            continue
        end
        visited{end+1} = name; %#ok<AGROW>
        try
            if ~bdIsLoaded(name)
                load_system(name);
            end
        catch ME
            smokeLog('skip', 'recurseModelReferences', b, ME, ['referenced model ' name ' not found']);
            continue
        end
        smokeLog('note', 'recurseModelReferences', b, ['referenced model ' name ' transformed in memory, not saved']);
        SMOKE(name, options{:});
    end
end
