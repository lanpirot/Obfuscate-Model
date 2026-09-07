function removeSubsystems(subsystems)
% REMOVESUBSYSTEMS Expand all SUBSYSTEMS into their parents ("squash"), so
% that their content is shown flatly. Subsystems that Simulink cannot expand
% (enabled, triggered, masked, variant, linked, ...) are kept and recorded.
    for i = 1:numel(subsystems)
        try
            Simulink.BlockDiagram.expandSubsystem(subsystems(i));
        catch ME
            smokeLog('skip', 'removeSubsystems', subsystems(i), ME);
        end
    end
end
