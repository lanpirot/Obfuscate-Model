function h = probeCopy(block, toDelete)
% PROBECOPY Copy BLOCK into a hidden scratch subsystem, to try parameter
% changes on the copy before applying them to the real block.
%
%   h = probeCopy(block)   handle of the copy, or -1 if it cannot be copied
%   probeCopy('-delete', h) delete a copy again
%   probeCopy('-clear')    close the scratch model

    persistent container
    scratch = 'SMOKE_scratch_probe';

    if ischar(block) && startsWith(block, '-')
        switch block
            case '-clear'
                container = [];
                if bdIsLoaded(scratch)
                    close_system(scratch, 0);
                end
            case '-delete'
                try
                    delete_block(toDelete);
                catch
                end
        end
        h = -1;
        return
    end

    if ~bdIsLoaded(scratch)
        new_system(scratch);
        container = [];
    end
    if isempty(container)
        container = add_block('built-in/SubSystem', [scratch '/probe']);
    end
    try
        h = add_block(getfullname(block), [scratch '/probe/copy'], 'MakeNameUnique', 'on', 'CopyOption', 'nolink');
    catch ME
        smokeLog('note', 'probeCopy', block, ME);
        h = -1;
    end
end
