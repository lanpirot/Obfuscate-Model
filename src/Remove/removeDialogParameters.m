function removeDialogParameters(blocks, keepConstantValue)
% REMOVEDIALOGPARAMETERS Reset the dialog parameters of all BLOCKS to defaults.
%   removeDialogParameters(blocks, true) leaves the Value of Constant blocks
%   to renameConstants, so that the two do not undo each other.
%
%   Simulink offers neither a reset nor a list of default values. The defaults
%   are therefore read from a pristine block of the same type (see
%   defaultBlock). Parameters the pristine block does not have (masks,
%   Stateflow, S-functions) are set to a neutral value: -17 for numbers,
%   x17 for identifiers (variable, function, or object names), '' for text.
%
%   The neutral value is -17 rather than 0 or 1, so that the reset never
%   lands on the value the model already had (see neutralValue).
%
%   Structure is preserved by construction: every change is first tried on a
%   scratch copy of the block (see probeCopy); if the copy's ports change, the
%   parameter is kept. If the copy cannot tell (e.g. the block refers to
%   workspace variables), the change is applied to the real block while
%   watching its ports; if a port appears or disappears, the parameter is
%   restored and the lines that hung on that port are reconnected. A few
%   parameters known to change the structure or to crash MATLAB are never
%   touched at all.
%
%   Every parameter that Simulink refuses to change is recorded in smokeLog.

    STRUCTURAL = {'Inputs', 'Outputs', 'VariantControl', 'VariantControlMode', 'LabelModeActiveChoice', ...
        'NumPorts', 'FrameSettings', 'Port', 'NumInputPorts', 'NumOutputPorts', 'BlockChoice', ...
        'ShowPortLabels', 'MemberBlocks', 'InitialConditionSource', 'Permissions', 'IsSimulinkFunction'};
    % Blocks that define the kind of their subsystem (triggered, enabled,
    % iterator, Simulink Function, ...). Their parameters are part of the
    % model structure, so they are left alone.
    KIND_BLOCKS = {'TriggerPort', 'EnablePort', 'ActionPort', 'ResetPort', 'ForIterator', 'WhileIterator', ...
        'ForEach', 'ArgIn', 'ArgOut', 'EventListener', 'StateReader', 'StateWriter'};
    % 'Parameters' (S-function parameters) crashed MATLAB when guessed blindly
    GUESS_EXCLUDE = [STRUCTURAL {'Parameters'}];
    rule = 'removeDialogParameters';
    if nargin < 2
        keepConstantValue = false;
    end

    for i = 1:numel(blocks)
        b = blocks(i);
        try
            blockType = get_param(b, 'BlockType');
            if ismember(blockType, KIND_BLOCKS)
                continue
            end
            params = writableParams(get_param(b, 'DialogParameters'));
        catch ME
            smokeLog('skip', rule, b, ME);
            continue
        end
        if isempty(params)
            continue
        end

        ref = defaultBlock(blockType);
        if ref < 0
            smokeLog('skip', rule, b, ['Simulink cannot create a default block of type ' blockType]);
            continue
        end
        refParams = writableParams(get_param(ref, 'DialogParameters'));
        probe = -1;
        if ~strcmp(blockType, 'SubSystem') % copying subsystems is expensive and their ports come from their content
            probe = probeCopy(b);
        end

        % 1) Parameters without a known default: neutral value.
        unknown = setdiff(params, refParams);
        for p = 1:numel(unknown)
            name = unknown{p};
            if ismember(name, GUESS_EXCLUDE)
                continue
            end
            try
                old = get_param(b, name);
                if isnumeric(old) || islogical(old)
                    new = neutralValue(old);
                elseif ischar(old) && ~isnan(str2double(old))
                    new = neutralValue(old);
                elseif ischar(old) && ~isempty(regexp(strtrim(old), '^[A-Za-z_]\w*$', 'once'))
                    new = neutralValue(old, 'name'); % '' is rejected where a name is expected
                elseif ischar(old) || isstring(old)
                    new = '';
                else
                    smokeLog('note', rule, b, ['parameter ' name ' of type ' class(old) ' not supported']);
                    continue
                end
                if isequal(old, new)
                    continue
                end
                guardedSet(b, probe, name, new, rule);
            catch ME
                smokeLog('skip', rule, b, ME, name);
            end
        end

        % 2) Parameters with a known default: copy it from the pristine block.
        known = intersect(params, refParams);
        for p = 1:numel(known)
            name = known{p};
            if ismember(name, STRUCTURAL)
                continue
            end
            try
                default = get_param(ref, name);
                % Setting a parameter to its current value crashed MATLAB for
                % some block types, so compare first.
                if isequal(get_param(b, name), default)
                    continue
                end
            catch ME
                smokeLog('skip', rule, b, ME, name);
                continue
            end
            isConstantValue = strcmp(blockType, 'Constant') && strcmp(name, 'Value');
            if isConstantValue && keepConstantValue
                continue
            end
            if any(strcmp(name, {'InitialCondition', 'Gain'})) || isConstantValue
                % a default of 0 or 1 here would often not change anything
                default = neutralValue(get_param(b, name));
            end
            try
                guardedSet(b, probe, name, default, rule)
            catch ME
                if strcmp(ME.identifier, 'Simulink:blocks:LookupMismatchedParams')
                    try
                        guardedSet(b, probe, name, '[ ]', rule)
                        continue
                    catch ME
                    end
                end
                smokeLog('skip', rule, b, ME, name);
            end
        end
        if probe > 0
            probeCopy('-delete', probe);
        end
    end
end

function guardedSet(block, probe, name, value, rule)
% Set NAME of BLOCK to VALUE unless that would change the block's ports.
    old = get_param(block, name);
    verdict = probeVerdict(probe, name, value, old); % 1 changes ports, 0 keeps them, -1 unknown
    if verdict == 1
        smokeLog('note', rule, block, ['parameter ' name ' kept: resetting it would change the ports']);
        return
    end
    if verdict == 0
        try
            set_param(block, name, value);
        catch ME
            try set_param(probe, name, old); catch, end % keep the copy in sync with the block
            rethrow(ME)
        end
        return
    end
    % Unknown: apply on the real block, ready to undo.
    before = get_param(block, 'Ports');
    lines = snapshotLines(block);
    set_param(block, name, value);
    if isequal(before, get_param(block, 'Ports'))
        return
    end
    set_param(block, name, old);
    restoreLines(block, lines);
    smokeLog('note', rule, block, ['parameter ' name ' kept: resetting it would change the ports']);
end

function verdict = probeVerdict(probe, name, value, old)
% Try the change on the scratch copy. The copy must stay identical to the
% real block, so a change that is not applied to the block is undone here.
    verdict = -1;
    if probe < 0
        return
    end
    try
        before = get_param(probe, 'Ports');
        set_param(probe, name, value);
        verdict = double(~isequal(before, get_param(probe, 'Ports')));
        if verdict == 1
            set_param(probe, name, old);
        end
    catch
    end
end

function snap = snapshotLines(block)
% Source port of every line into the block, and destination ports of every
% line out of it, so that they can be reconnected if a port vanishes.
    snap = struct('in', {{}}, 'out', {{}});
    try
        lh = get_param(block, 'LineHandles');
        for k = 1:numel(lh.Inport)
            src = -1;
            if lh.Inport(k) > 0
                src = get_param(lh.Inport(k), 'SrcPortHandle');
            end
            snap.in{k} = src;
        end
        for k = 1:numel(lh.Outport)
            dst = [];
            if lh.Outport(k) > 0
                dst = get_param(lh.Outport(k), 'DstPortHandle');
                dst = dst(dst > 0);
            end
            snap.out{k} = dst(:)';
        end
    catch
    end
end

function restoreLines(block, snap)
    try
        parent = get_param(block, 'Parent');
        ph = get_param(block, 'PortHandles');
        lh = get_param(block, 'LineHandles');
        for k = 1:min(numel(snap.in), numel(ph.Inport))
            if snap.in{k} > 0 && lh.Inport(k) < 0
                add_line(parent, snap.in{k}, ph.Inport(k));
            end
        end
        for k = 1:min(numel(snap.out), numel(ph.Outport))
            for dst = snap.out{k}
                if get_param(dst, 'Line') < 0
                    add_line(parent, ph.Outport(k), dst);
                end
            end
        end
    catch
    end
end

function names = writableParams(dialogParams)
% Names of the dialog parameters that are not read-only.
    if isempty(dialogParams)
        names = cell(0, 1);
        return
    end
    names = fieldnames(dialogParams);
    keep = true(size(names));
    for k = 1:numel(names)
        attr = dialogParams.(names{k});
        if isstruct(attr) && isfield(attr, 'Attributes') && any(strcmp(attr.Attributes, 'read-only'))
            keep(k) = false;
        end
    end
    names = names(keep);
end
