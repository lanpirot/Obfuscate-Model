function unlockModel(startSys, subsystems)
% UNLOCKMODEL Unlock the model of STARTSYS (libraries are locked by default)
% and make STARTSYS (if it is a subsystem) and all SUBSYSTEMS writable.
    if strcmp(get_param(startSys, 'Type'), 'block')
        subsystems = [startSys; subsystems(:)];
    end
    root = bdroot(startSys);
    try
        if strcmp(get_param(root, 'BlockDiagramType'), 'library')
            set_param(root, 'Lock', 'off');
        end
    catch ME
        smokeLog('skip', 'unlockModel', root, ME);
    end
    for i = 1:numel(subsystems)
        s = subsystems(i);
        try
            if ~strcmp(get_param(s, 'Permissions'), 'ReadWrite')
                set_param(s, 'Permissions', 'ReadWrite')
            end
        catch ME
            smokeLog('skip', 'unlockModel', s, ME);
        end
    end
end
