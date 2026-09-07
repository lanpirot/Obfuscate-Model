function hideContentPreview(subsystems)
% HIDECONTENTPREVIEW Switch off the content preview of all SUBSYSTEMS.
    for i = 1:numel(subsystems)
        s = subsystems(i);
        try
            if ~strcmpi(get_param(s, 'ContentPreviewEnabled'), 'off')
                set_param(s, 'ContentPreviewEnabled', 'off');
            end
        catch ME
            smokeLog('skip', 'hideContentPreview', s, ME);
        end
    end
end
