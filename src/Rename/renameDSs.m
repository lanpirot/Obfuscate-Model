function renameDSs(memories, writes, reads, startSys)
% RENAMEDSS Give all data stores generic names (DataStore1, DataStore2, ...).
% All Data Store Memory, Read, and Write blocks that share a name are renamed
% together, so that the model keeps working. Names that are also used
% outside the scope are kept, otherwise the blocks inside would be cut off.

    renameShared([memories(:); writes(:); reads(:)], 'DataStoreName', 'DataStore', ...
        {'DataStoreMemory', 'DataStoreWrite', 'DataStoreRead'}, startSys, 'renameDSs');
end
