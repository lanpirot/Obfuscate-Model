function renameStateflow(startSys, depth, opt)
% RENAMESTATEFLOW Rename the Stateflow objects of all charts inside STARTSYS
% (down to DEPTH levels) to generic names. OPT selects what to rename:
% sfcharts, sfports, sfevents, sfboxes, sfstates, sffunctions, sflabels.

    scopePath = getfullname(startSys);
    model = sfroot().find('-isa', 'Simulink.BlockDiagram', '-and', 'Name', bdroot(scopePath));
    if isempty(model)
        return
    end
    charts = model.find('-isa', 'Stateflow.Chart');

    for i = 1:length(charts)
        c = charts(i);
        if ~inScope(c.Path, scopePath, depth)
            continue
        end

        if opt.sfcharts
            try
                c.Name = ['StateflowChart' num2str(i)];
            catch ME
                smokeLog('skip', 'renameStateflow', c, ME, 'chart name');
            end
        end

        if opt.sfports
            renameAll(c.find('-isa', 'Stateflow.Data', 'Scope', 'Input'), 'Input');
            renameAll(c.find('-isa', 'Stateflow.Data', 'Scope', 'Output'), 'Output');
        end

        if opt.sfevents
            renameAll(c.find('-isa', 'Stateflow.Event'), 'Event');
        end

        if opt.sfboxes
            renameAll(c.find('-isa', 'Stateflow.Box'), 'Box');
        end

        if opt.sfstates
            % grouped boxes protect their content; ungroup temporarily
            boxes = c.find('-isa', 'Stateflow.Box');
            grouped = arrayfun(@(b) b.IsGrouped, boxes);
            for b = 1:numel(boxes)
                try
                    boxes(b).IsGrouped = 0;
                catch
                end
            end
            states = c.find('-isa', 'Stateflow.State');
            for m = 1:length(states)
                try
                    states(m).Name = ['State' num2str(m)];
                    states(m).LabelString = ['State' num2str(m)];
                catch ME
                    smokeLog('skip', 'renameStateflow', states(m), ME, 'state');
                end
            end
            for b = 1:numel(boxes)
                try
                    boxes(b).IsGrouped = grouped(b);
                catch
                end
            end
        end

        if opt.sffunctions
            renameAll([c.find('-isa', 'Stateflow.Function'); c.find('-isa', 'Stateflow.SLFunction')], 'function');
        end

        if opt.sflabels
            transitions = c.find('-isa', 'Stateflow.Transition');
            for t = 1:length(transitions)
                try
                    transitions(t).LabelString = relabel(transitions(t).LabelString);
                catch ME
                    smokeLog('skip', 'renameStateflow', transitions(t), ME, 'transition label');
                end
            end
        end
    end
end

function tf = inScope(path, scopePath, depth)
    if strcmp(path, scopePath)
        tf = true;
    elseif startsWith(path, [scopePath '/'])
        rest = path(length(scopePath) + 2:end);
        tf = isinf(depth) || ~contains(rest, '/');
    else
        tf = false;
    end
end

function renameAll(objects, prefix)
    for j = 1:length(objects)
        try
            objects(j).Name = [prefix num2str(j)];
        catch ME
            smokeLog('skip', 'renameStateflow', objects(j), ME, prefix);
        end
    end
end

function label = relabel(label)
% Shorten identifiers in a transition label to two characters and numbers to 0.
    tokens = regexp(label, '[\(\)\[\],<>=\s]+', 'split');
    for i = 1:length(tokens)
        token = regexprep(tokens{i}, '[_\-{}.;~]', '');
        if isempty(token)
            continue
        end
        if ~isnan(str2double(token))
            label = strrep(label, tokens{i}, '0');
        elseif all(isstrprop(token, 'alphanum')) && strlength(token) > 1
            label = strrep(label, tokens{i}, tokens{i}(1:2));
        end
    end
end
