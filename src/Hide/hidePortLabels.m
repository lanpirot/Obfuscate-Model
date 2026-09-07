function hidePortLabels(subsystems)
% HIDEPORTLABELS Hide the port labels shown on all SUBSYSTEMS.
    for i = 1:numel(subsystems)
        s = subsystems(i);
        try
            if ~strcmpi(get_param(s, 'ShowPortLabels'), 'none')
                set_param(s, 'ShowPortLabels', 'none');
            end
        catch ME
            smokeLog('skip', 'hidePortLabels', s, ME);
        end
    end
end
