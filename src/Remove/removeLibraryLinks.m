function removeLibraryLinks(blocks)
% REMOVELIBRARYLINKS Break the library links of all linked BLOCKS, so that the
% blocks are stored in the model itself. Simscape blocks are left alone.

    for i = 1:numel(blocks)
        b = blocks(i);
        try
            if strcmp(get_param(b, 'StaticLinkStatus'), 'none')
                continue
            end
            ports = get_param(b, 'PortHandles');
            if startsWith(get_param(b, 'BlockType'), 'Simscape') || ~isempty(ports.LConn) || ~isempty(ports.RConn)
                smokeLog('note', 'removeLibraryLinks', b, 'Simscape block, link kept');
                continue
            end
            set_param(b, 'LinkStatus', 'none');
        catch ME
            smokeLog('skip', 'removeLibraryLinks', b, ME);
        end
    end
end
