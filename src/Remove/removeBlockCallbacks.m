function removeBlockCallbacks(blocks)
% REMOVEBLOCKCALLBACKS Clear the callback parameters of all BLOCKS.
% Callbacks may contain arbitrary MATLAB code.
%
% See: https://www.mathworks.com/help/simulink/ug/block-callbacks.html

    callbacks = {'CopyFcn' 'DeleteFcn' 'LoadFcn' 'ModelCloseFcn' 'PreSaveFcn' 'PostSaveFcn' ...
        'InitFcn' 'StartFcn' 'PauseFcn' 'ContinueFcn' 'StopFcn' 'NameChangeFcn' 'ClipboardFcn' ...
        'DestroyFcn' 'PreCopyFcn' 'OpenFcn' 'CloseFcn' 'PreDeleteFcn' 'ParentCloseFcn' 'MoveFcn' 'PreLoadFcn'};
    for i = 1:numel(blocks)
        b = blocks(i);
        for c = 1:numel(callbacks)
            try
                value = get_param(b, callbacks{c});
            catch
                continue % this block type has no such callback
            end
            if isempty(value)
                continue
            end
            try
                set_param(b, callbacks{c}, '');
            catch ME
                smokeLog('skip', 'removeBlockCallbacks', b, ME, callbacks{c});
            end
        end
    end
end
