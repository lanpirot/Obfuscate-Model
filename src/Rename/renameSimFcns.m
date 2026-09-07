function renameSimFcns(triggers)
% RENAMESIMFCNS Rename all Simulink Functions (identified by their TRIGGERS)
% to f1, f2, ... and update their Function Callers.
    num = 0;
    for i = 1:numel(triggers)
        t = triggers(i);
        try
            if ~strcmp(get_param(t, 'IsSimulinkFunction'), 'on')
                continue
            end
            simFcn = get_param(t, 'Parent');
            callers = findCallers(simFcn);
            num = num + 1;
            newName = sprintf('f%d', num);
            set_param(t, 'FunctionName', newName);
        catch ME
            smokeLog('skip', 'renameSimFcns', t, ME);
            continue
        end
        if ~isempty(callers)
            updateCallers(simFcn, callers, newName)
        end
    end
end
