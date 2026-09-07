function updateCallers(simFcn, callers, fcnName)
% UPDATECALLERS Update the function prototype of all callers of a Simulink Function.
%   Must be called after the function name or its argument names changed,
%   otherwise the Function Caller blocks keep the stale prototype. A caller
%   that used a qualifier before (e.g. 'y = Sub.f(u)') keeps its qualifier.
%
%   (Restored from the original Obfuscate-Model tool by McSCert.)

    try
        prototype = getPrototype(simFcn);
    catch ME
        smokeLog('skip', 'updateCallers', simFcn, ME);
        return
    end
    for i = 1:length(callers)
        try
            old = get_param(callers{i}, 'FunctionPrototype');
            qualifier = regexp(old, '(\w+)\.\w+\s*\(', 'tokens', 'once');
            p = prototype;
            if ~isempty(qualifier)
                if contains(p, '=')
                    p = insertAfter(p, '= ', [qualifier{1} '.']);
                else
                    p = [qualifier{1} '.' p];
                end
            end
            set_param(callers{i}, 'FunctionPrototype', p);
            if ~isempty(fcnName)
                set_param(callers{i}, 'Name', [fcnName '_caller_' num2str(i)]);
            end
        catch ME
            smokeLog('skip', 'updateCallers', callers{i}, ME);
        end
    end
end
