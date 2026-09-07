function renameArgs(argIns, argOuts)
% RENAMEARGS Give all Simulink Function arguments generic names (u1, u2, ...
% for inputs, y1, y2, ... for outputs) and update the Function Callers.
    renameGroup(argIns, 'u');
    renameGroup(argOuts, 'y');
end

function renameGroup(args, prefix)
    for i = 1:numel(args)
        a = args(i);
        try
            simFcn = get_param(a, 'Parent');
            callers = findCallers(simFcn);
        catch ME
            smokeLog('skip', 'renameArgs', a, ME);
            continue
        end
        renamed = false;
        for num = 1:100
            try
                set_param(a, 'ArgumentName', sprintf('%s%d', prefix, num));
                renamed = true;
                break
            catch ME
                if ~isNameClash(ME)
                    smokeLog('skip', 'renameArgs', a, ME);
                    break
                end
            end
        end
        if renamed && ~isempty(callers)
            updateCallers(simFcn, callers, []);
        end
    end
end

function tf = isNameClash(ME)
    tf = contains(lower(ME.message), {'exist', 'unique', 'already', 'in use', 'duplicate'});
end
