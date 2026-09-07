function test_basics()
% TEST_BASICS Fast sanity test of SMOKE on a small, generated model.
%
%   Builds a model that contains one instance of every element SMOKE
%   handles, with a recognisable "secret" string in each, runs SMOKE, and
%   checks on the saved raw model file that
%     1. every secret is gone,
%     2. secrets outside the chosen scope are still there,
%     3. the model structure (blocks, subsystems, connections) is unchanged.
%   Prints PASS/FAIL per check. Runs in well under a minute.
%
%   This covers the basics only. Real-world corner cases are covered by
%   test_scalability.m on the SLNET corpus.

    tmp = tempname; mkdir(tmp);
    oldDir = cd(tmp);
    warnState = warning('off', 'all');
    cleanup = onCleanup(@() restore(oldDir, warnState)); %#ok<NASGU>
    bdclose all
    failures = 0;

    %% 1. Whole model
    name = 'smoke_basics';
    build(name);
    save_system(name, [name '.mdl']);
    before = fileread([name '.mdl']);
    structBefore = structure(name);

    report = SMOKE(name, allBut('squashSubsystems'));
    structAfter = structure(name);
    save_system(name, [name '_out.mdl']); % note: renames the loaded model
    after = fileread([name '_out.mdl']);
    bdclose all

    secrets = allSecrets();
    for i = 1:numel(secrets)
        failures = failures + check(contains(before, secrets{i}), ['fixture contains ' secrets{i}]);
        failures = failures + check(~contains(after, secrets{i}), ['removed ' secrets{i}]);
    end
    failures = failures + check(isequal(structBefore, structAfter), ...
        sprintf('structure unchanged (blocks/subsystems/connections %s -> %s)', mat2str(structBefore), mat2str(structAfter)));
    failures = failures + check(~any(strcmp(report.rule, 'updateCallers')), 'function callers updated');
    failures = failures + check(~contains(after, 'DocBlock'), 'DocBlock deleted');

    %% 2. Scope: only subsystem A, B must stay untouched
    build(name);
    set_param(0, 'CurrentSystem', [name '/A']); % like clicking into A, without opening a window
    SMOKE(name, allBut('completeModel'));
    save_system(name, [name '_scope.mdl']);
    scoped = fileread([name '_scope.mdl']);
    bdclose all
    for i = 1:numel(secrets)
        s = secrets{i};
        if endsWith(s, '_B')
            failures = failures + check(contains(scoped, s), ['scope: kept outside ' s]);
        elseif endsWith(s, '_A')
            failures = failures + check(~contains(scoped, s), ['scope: removed inside ' s]);
        end
    end

    skipped = report(strcmp(report.kind, 'skip'), {'rule', 'element', 'detail', 'identifier', 'message'});
    if ~isempty(skipped)
        fprintf('\nSkipped by SMOKE on the fixture:\n');
        disp(skipped)
    end
    %% 3. Dialog parameters alone must also sanitize mask parameters (identifiers)
    build(name);
    SMOKE(name, 'removedialogparameters', 1, 'completeModel', 1);
    save_system(name, [name '_dialog.mdl']);
    dialogOnly = fileread([name '_dialog.mdl']);
    bdclose all
    failures = failures + check(~contains(dialogOnly, 'secretMaskParam'), 'dialog parameters: mask parameter identifier replaced');
    failures = failures + check(~contains(dialogOnly, 'SecretConst'), 'dialog parameters: constant variable replaced');

    if failures == 0
        fprintf('\nALL PASSED\n');
    else
        fprintf('\n%d FAILED\n', failures);
    end
end

function restore(oldDir, warnState)
    cd(oldDir);
    warning(warnState);
end

function n = check(ok, what)
    if ok
        fprintf('PASS  %s\n', what);
        n = 0;
    else
        fprintf('FAIL  %s\n', what);
        n = 1;
    end
end

function s = allSecrets()
    s = {};
    for suffix = {'_A', '_B'}
        x = suffix{1};
        s = [s, {['SecretBlock' x], ['SecretSignal' x], ['SecretConst' x], ['SecretTag' x], ...
            ['SecretStore' x], ['SecretNote' x], ['SecretDescription' x], ['SecretState' x], ...
            ['SecretChart' x], ['secretMaskParam' x], ['secretCallback' x], ['secretFcnBody' x]}]; %#ok<AGROW>
    end
    s = [s, {'SecretSimFcn', 'secretArg', 'SecretCreator'}];
end

function build(name)
    new_system(name);
    set_param(name, 'Creator', 'SecretCreator');
    for suffix = {'_A', '_B'}
        x = suffix{1};
        sub = [name '/' x(2)];
        add_block('built-in/SubSystem', sub);
        fill(sub, x);
    end
    % Simulink Function with a caller (exercises updateCallers)
    fcn = [name '/SecretSimFcnSub'];
    add_block('simulink/User-Defined Functions/Simulink Function', fcn);
    set_param([fcn '/f'], 'FunctionName', 'SecretSimFcn');
    set_param([fcn '/u'], 'ArgumentName', 'secretArgIn');
    set_param([fcn '/y'], 'ArgumentName', 'secretArgOut');
    add_block('simulink/User-Defined Functions/Function Caller', [name '/Caller'], ...
        'FunctionPrototype', 'secretArgOut = SecretSimFcn(secretArgIn)');
    add_block('built-in/Constant', [name '/CallIn'], 'Value', '1');
    add_block('built-in/Terminator', [name '/CallOut']);
    add_line(name, 'CallIn/1', 'Caller/1');
    add_line(name, 'Caller/1', 'CallOut/1');
    % DocBlock
    add_block('simulink/Model-Wide Utilities/DocBlock', [name '/Doc']);
end

function flags = allBut(off)
% All SMOKE options switched on, except OFF (and the two that are off by default).
    names = {'removemasks', 'removelibrarylinks', 'removesignalnames', 'removedocblocks', 'removeannotations', ...
        'removedescriptions', 'removeblockcallbacks', 'removemodelinformation', 'customdatatypes', ...
        'removecolorblocks', 'removecolorannotations', 'removedialogparameters', 'removefunctions', ...
        'removepositioning', 'removesizes', 'squashSubsystems', 'renameblocks', 'renameconstants', ...
        'renamegotofromtag', 'renamedatastorename', 'renamearguments', 'renamefunctions', ...
        'hidecontentpreview', 'hideportlabels', 'sfcharts', 'sfports', 'sfevents', 'sfstates', 'sfboxes', ...
        'sffunctions', 'sflabels', 'recursemodels', 'completeModel', 'recurseSubsystems'};
    values = num2cell(~strcmp(names, off));
    flags = reshape([names; values], 1, []);
end

function fill(sub, x)
    % blocks with names, colors, description, callback
    c = add_block('built-in/Constant', [sub '/SecretBlock' x], 'Value', ['SecretConst' x], ...
        'BackgroundColor', 'red', 'Description', ['SecretDescription' x], 'OpenFcn', ['secretCallback' x]);
    g = add_block('built-in/Gain', [sub '/Gain' x], 'Gain', '3');
    o = add_block('built-in/Outport', [sub '/Out' x]);
    l = add_line(sub, ['SecretBlock' x '/1'], ['Gain' x '/1']);
    set_param(l, 'Name', ['SecretSignal' x]);
    add_line(sub, ['Gain' x '/1'], ['Out' x '/1']);
    % goto/from, including a dangling From
    add_block('built-in/Goto', [sub '/Goto' x], 'GotoTag', ['SecretTag' x]);
    add_block('built-in/From', [sub '/From' x], 'GotoTag', ['SecretTag' x]);
    add_block('built-in/From', [sub '/Dangling' x], 'GotoTag', ['SecretTag' x 'Dangling']);
    add_block('built-in/Terminator', [sub '/T1' x]);
    add_block('built-in/Terminator', [sub '/T2' x]);
    add_block('built-in/Constant', [sub '/C2' x], 'Value', '2');
    add_line(sub, ['C2' x '/1'], ['Goto' x '/1']);
    add_line(sub, ['From' x '/1'], ['T1' x '/1']);
    add_line(sub, ['Dangling' x '/1'], ['T2' x '/1']);
    % data store
    add_block('built-in/DataStoreMemory', [sub '/DSM' x], 'DataStoreName', ['SecretStore' x]);
    add_block('built-in/DataStoreWrite', [sub '/DSW' x], 'DataStoreName', ['SecretStore' x]);
    add_block('built-in/DataStoreRead', [sub '/DSR' x], 'DataStoreName', ['SecretStore' x]);
    add_block('built-in/Constant', [sub '/C3' x], 'Value', '3');
    add_block('built-in/Terminator', [sub '/T3' x]);
    add_line(sub, ['C3' x '/1'], ['DSW' x '/1']);
    add_line(sub, ['DSR' x '/1'], ['T3' x '/1']);
    % annotation
    add_block('built-in/Note', [sub '/SecretNote' x], 'Position', [300 300]);
    % masked subsystem with a mask parameter
    m = add_block('built-in/SubSystem', [sub '/Masked' x]);
    mask = Simulink.Mask.create(m);
    mask.addParameter('Name', 'p', 'Prompt', 'p', 'Value', ['secretMaskParam' x]);
    % MATLAB Function block with code
    f = add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/MLF' x]);
    cfg = get_param(f, 'MATLABFunctionConfiguration');
    cfg.FunctionScript = sprintf('function y = fcn(u)\n%% secretFcnBody%s\ny = u;\n', x);
    % Stateflow chart with a state
    ch = add_block('sflib/Chart', [sub '/SecretChart' x]);
    rt = sfroot();
    chart = rt.find('-isa', 'Stateflow.Chart', 'Path', getfullname(ch));
    st = Stateflow.State(chart);
    st.Name = ['SecretState' x];
    st.Position = [10 10 80 60];
end

function s = structure(name)
    common = {'LookUnderMasks', 'all', 'MatchFilter', @Simulink.match.allVariants};
    blocks = find_system(name, common{:}, 'Type', 'Block');
    types = get_param(blocks, 'BlockType');
    nonDoc = ~strcmp(get_param(blocks, 'MaskType'), 'DocBlock');
    lines = find_system(name, common{:}, 'FindAll', 'on', 'Type', 'Line');
    n = 0;
    for i = 1:numel(lines)
        if get_param(lines(i), 'SrcPortHandle') > 0
            n = n + sum(get_param(lines(i), 'DstPortHandle') > 0);
        end
    end
    s = [sum(nonDoc), sum(strcmp(types, 'SubSystem') & nonDoc), n];
end
