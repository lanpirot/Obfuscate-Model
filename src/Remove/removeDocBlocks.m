function removeDocBlocks(docBlocks)
% REMOVEDOCBLOCKS Delete all DOCBLOCKS.
    for i = 1:numel(docBlocks)
        try
            delete_block(docBlocks(i));
        catch ME
            smokeLog('skip', 'removeDocBlocks', docBlocks(i), ME);
        end
    end
end
