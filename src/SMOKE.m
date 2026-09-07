function report = SMOKE(sys, varargin)
% SMOKE Obfuscate and sanitize a Simulink model while keeping its structure.
%
%   SMOKE(sys)                   apply all default transformations to model SYS
%   SMOKE(sys, name, value, ...) apply only the transformations switched on
%   report = SMOKE(...)          also return the table of skipped elements
%
%   SYS is a model name or handle. The scope is the whole model by default;
%   with 'completeModel', 0 it is the currently open subsystem (gcs), either
%   alone ('recurseSubsystems', 0) or with everything nested in it.
%
%   Policy: SMOKE never aborts because of a single element. When Simulink
%   refuses a change (locked links, read-only subsystems, blocks that cannot
%   be resized, ...) that element is skipped and recorded. A summary is
%   printed at the end; smokeLog('report') lists every skipped element so
%   that the user can inspect what is still untouched.
%
%   Options. When no option is given, all of them are on except those marked
%   (off). When at least one option is given, all others are off.
%
%   Remove:  removemasks, removelibrarylinks, removemodelreferences (off),
%            removesignalnames, removedocblocks, removeannotations,
%            removedescriptions, removeblockcallbacks, removemodelinformation,
%            customdatatypes, removecolorblocks, removecolorannotations,
%            removedialogparameters, removefunctions, removepositioning,
%            removesizes, squashSubsystems, removeImplement (off)
%   Rename:  renameblocks, renameconstants, renamegotofromtag,
%            renamedatastorename, renamearguments, renamefunctions
%   Stateflow: sfcharts, sfports, sfevents, sfstates, sfboxes, sffunctions,
%            sflabels (renameStateFlow switches all of them off when 0)
%   Hide:    hidecontentpreview, hideportlabels
%   Scope:   completeModel, recurseSubsystems, recursemodels
%
%   Example:
%       SMOKE('sldemo_auto_climatecontrol', 'removeannotations', 1, 'renameblocks', 1)

    %% Options
    if numel(varargin) == 1 && iscell(varargin{1})
        varargin = varargin{1}; % SMOKE(sys, {name, value, ...}) is accepted too
    end
    default = double(isempty(varargin));
    names = {'removemasks', 'removelibrarylinks', 'removemodelreferences', 'removesignalnames', ...
        'removedocblocks', 'removeannotations', 'removedescriptions', 'removeblockcallbacks', ...
        'removemodelinformation', 'customdatatypes', 'removecolorblocks', 'removecolorannotations', ...
        'removedialogparameters', 'removefunctions', 'removepositioning', 'removesizes', ...
        'squashSubsystems', 'removeImplement', ...
        'renameblocks', 'renameconstants', 'renamegotofromtag', 'renamedatastorename', ...
        'renamearguments', 'renamefunctions', 'renameStateFlow', ...
        'hidecontentpreview', 'hideportlabels', ...
        'sfcharts', 'sfports', 'sfevents', 'sfstates', 'sfboxes', 'sffunctions', 'sflabels', ...
        'recursemodels', 'completeModel', 'recurseSubsystems'};
    alwaysOff = {'removemodelreferences', 'removeImplement'};
    opt = struct();
    for i = 1:numel(names)
        d = default;
        if ismember(names{i}, alwaysOff)
            d = 0;
        end
        opt.(names{i}) = logical(getInput(names{i}, varargin, d));
    end
    % The GUI only passes the individual Stateflow options.
    sfNames = {'sfcharts', 'sfports', 'sfevents', 'sfstates', 'sfboxes', 'sffunctions', 'sflabels'};
    if ~opt.renameStateFlow && isempty(getInput('renameStateFlow', varargin, []))
        opt.renameStateFlow = any(cellfun(@(n) opt.(n), sfNames));
    end

    %% Bookkeeping (SMOKE recurses into referenced models)
    depth = smokeLog('enter');
    leaveGuard = onCleanup(@() smokeLog('leave')); %#ok<NASGU>
    if depth == 1
        smokeLog('reset');
        defaultBlock('-clear');
        probeCopy('-clear');
        recurseModelReferences('-reset');
    end

    %% Scope
    sys = get_param(sys, 'Handle');
    startSys = sys;
    if ~opt.completeModel
        current = gcs;
        if ~isempty(current) && strcmp(bdroot(current), get_param(sys, 'Name'))
            startSys = get_param(current, 'Handle');
        else
            smokeLog('note', 'scope', sys, 'current subsystem is not in this model, using the whole model');
        end
    end
    if opt.recurseSubsystems || opt.completeModel
        depthArg = inf;
    else
        depthArg = 1;
    end

    els = collectElements(startSys, depthArg);
    unlockModel(startSys, els.subsystems);

    %% Referenced models
    if ~opt.removemodelreferences && opt.recursemodels
        passOn = opt;
        passOn.completeModel = true;
        passOn.recurseSubsystems = true;
        passOn = reshape([fieldnames(passOn)'; struct2cell(passOn)'], 1, []);
        recurseModelReferences(els.ofType('ModelReference'), passOn);
    end

    %% Transformations that remove elements first
    if opt.removelibrarylinks
        removeLibraryLinks(els.blocks)
        els = collectElements(startSys, depthArg); % linked content is now visible
        unlockModel(startSys, els.subsystems);
    end

    if opt.removedocblocks
        docBlocks = [];
        if ~isempty(els.subsystems)
            docBlocks = els.subsystems(strcmp(get_param(els.subsystems, 'MaskType'), 'DocBlock'));
        end
        if ~isempty(docBlocks)
            removeDocBlocks(docBlocks)
            els = collectElements(startSys, depthArg);
        end
    end

    if opt.removemasks
        removeMasks(els.blocks)
    end

    if opt.removeblockcallbacks
        removeBlockCallbacks(els.blocks)
    end

    if opt.removemodelreferences
        removeModelReferences(els.ofType('ModelReference'))
    end

    if opt.removeImplement
        removeImplementation(startSys)
        els = collectElements(startSys, depthArg);
    end

    if opt.removesignalnames
        removeSignalNames(els.lines, els.blocks)
    end

    if opt.removedescriptions
        removeDescriptions([els.blocks; els.lines; els.annotations])
    end

    if opt.squashSubsystems
        removeSubsystems(els.subsystems);
        els = collectElements(startSys, depthArg);
    end

    if opt.removecolorannotations
        removeAnnotationColors(els.annotations)
    end

    if opt.removeannotations
        removeAnnotations(els.annotations, els.blocks)
        els.annotations = [];
    end

    if opt.removecolorblocks
        removeBlockColors(els.blocks)
    end

    if opt.removemodelinformation
        removeModelInformation(sys)
    end

    if opt.removedialogparameters
        removeDialogParameters(els.blocks, opt.renameconstants)
    end

    if opt.removefunctions
        removeFunctions(els.subsystems)
    end

    if opt.customdatatypes
        removeCustomDataTypes(els.ofType('Inport'))
    end

    if opt.hidecontentpreview
        hideContentPreview(els.subsystems);
    end

    if opt.hideportlabels
        hidePortLabels(els.subsystems);
    end

    %% Rename
    if opt.renameconstants
        renameConstants(els.ofType('Constant'))
    end

    if opt.renamegotofromtag
        renameGotoTags(els.ofType('Goto'), els.ofType('From'), startSys)
    end

    if opt.renamedatastorename
        renameDSs(els.ofType('DataStoreMemory'), els.ofType('DataStoreWrite'), els.ofType('DataStoreRead'), startSys)
    end

    if opt.renamearguments
        renameArgs(els.ofType('ArgIn'), els.ofType('ArgOut'));
    end

    if opt.renamefunctions
        renameSimFcns(els.ofType('TriggerPort'));
    end

    if opt.renameStateFlow
        renameStateflow(startSys, depthArg, opt);
    end

    if opt.renameblocks
        renameBlocks(els.blocks)
    end

    %% Layout last: sizes depend on names, positions on sizes
    if opt.removesizes
        removeSizes(els.blocks)
    end

    if opt.removepositioning
        systems = startSys;
        if isinf(depthArg)
            systems = [startSys; els.subsystems];
        end
        removePositioning(els.blocks, systems)
    end

    %% Report
    if depth == 1
        defaultBlock('-clear');
        probeCopy('-clear');
        smokeLog('print');
    end
    if nargout > 0
        report = smokeLog('report');
    end
end
