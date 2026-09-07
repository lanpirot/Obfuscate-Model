function els = collectElements(startSys, depth)
% COLLECTELEMENTS Gather all model elements inside the scope of SMOKE.
%
%   els = collectElements(startSys, depth) searches the model or subsystem
%   STARTSYS down to DEPTH (1 = this level only, inf = whole tree), looking
%   under masks and into all variants. Everything SMOKE transforms is derived
%   from this one collection, so the scope is enforced in a single place.
%
%   els.start        handle of the scope root
%   els.blocks       block handles inside the scope (the root itself belongs
%                    to the parent view and is not included)
%   els.blockTypes   BlockType of every entry in els.blocks
%   els.ofType(t)    blocks of BlockType t
%   els.subsystems   blocks of type SubSystem
%   els.lines        line handles
%   els.annotations  annotation handles

    common = {'LookUnderMasks', 'all', 'MatchFilter', @Simulink.match.allVariants};
    start = get_param(startSys, 'Handle');

    blocks = find_system(start, 'SearchDepth', depth, common{:}, 'Type', 'Block');
    blocks = blocks(:);
    blocks = blocks(blocks ~= start);
    if isempty(blocks)
        types = cell(0, 1);
    else
        types = get_param(blocks, 'BlockType');
        if ~iscell(types)
            types = {types};
        end
    end

    els.start = start;
    els.depth = depth;
    els.blocks = blocks;
    els.blockTypes = types;
    els.ofType = @(t) blocks(strcmp(types, t));
    els.subsystems = blocks(strcmp(types, 'SubSystem'));
    els.lines = find_system(start, 'SearchDepth', depth, 'FindAll', 'on', common{:}, 'Type', 'Line');
    els.lines = els.lines(:);
    els.annotations = find_system(start, 'SearchDepth', depth, 'FindAll', 'on', common{:}, 'Type', 'Annotation');
    els.annotations = els.annotations(:);
end
