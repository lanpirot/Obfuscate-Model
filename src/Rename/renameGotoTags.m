function renameGotoTags(gotos, froms, startSys)
% RENAMEGOTOTAGS Give all Goto/From tags generic names (GotoFrom1, ...).
% Gotos and Froms that share a tag are renamed together, so that the model
% keeps working. Tags that are also used outside the scope are kept,
% otherwise the blocks inside would be cut off.

    renameShared([gotos(:); froms(:)], 'GotoTag', 'GotoFrom', {'Goto', 'From'}, startSys, 'renameGotoTags');
end
