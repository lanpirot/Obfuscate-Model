function out = smokeLog(action, rule, element, ME, detail)
% SMOKELOG Collect model elements that SMOKE could not transform.
%
%   SMOKE never aborts because of a single element. When Simulink refuses a
%   change, the failure is recorded here and the run continues. After the run
%   the report tells the user which elements are still untouched, so they can
%   inspect them by hand.
%
%   smokeLog('reset')                          start a new, empty report
%   smokeLog('skip', rule, element, ME)        RULE could not be applied to ELEMENT
%   smokeLog('skip', rule, element, ME, detail)   ... with extra detail (e.g. a parameter name)
%   smokeLog('note', rule, element, text)      informational entry, nothing was skipped
%   t = smokeLog('report')                     table of all entries
%   n = smokeLog('count')                      number of skipped transformations
%   smokeLog('print')                          summary on the command window
%   d = smokeLog('enter') / smokeLog('leave')  nesting depth of SMOKE calls
%                                              (SMOKE recurses into referenced models)

    persistent entries nesting
    if isempty(entries)
        entries = newEntries();
    end
    if isempty(nesting)
        nesting = 0;
    end
    if nargin < 5
        detail = '';
    end

    switch action
        case 'reset'
            entries = newEntries();
        case {'skip', 'note'}
            if nargin < 4
                ME = '';
            end
            if isa(ME, 'MException')
                id = ME.identifier;
                msg = ME.message;
            else
                id = '';
                msg = char(string(ME));
            end
            entries.kind{end+1, 1} = action;
            entries.rule{end+1, 1} = char(rule);
            entries.element{end+1, 1} = elementName(element);
            entries.detail{end+1, 1} = char(detail);
            entries.identifier{end+1, 1} = id;
            entries.message{end+1, 1} = regexprep(msg, '\s+', ' ');
        case 'report'
            out = struct2table(entries);
        case 'count'
            out = sum(strcmp(entries.kind, 'skip'));
        case 'print'
            printSummary(entries);
        case 'enter'
            nesting = nesting + 1;
            out = nesting;
        case 'leave'
            nesting = max(nesting - 1, 0);
            out = nesting;
        otherwise
            error('SMOKE:smokeLog:unknownAction', 'Unknown action ''%s''.', action);
    end
end

function e = newEntries()
    e = struct('kind', {cell(0, 1)}, 'rule', {cell(0, 1)}, 'element', {cell(0, 1)}, ...
        'detail', {cell(0, 1)}, 'identifier', {cell(0, 1)}, 'message', {cell(0, 1)});
end

function name = elementName(el)
% Human readable path of a block, line, annotation, port, model, or Stateflow object.
    try
        if iscell(el)
            el = el{1};
        end
        if ischar(el) || isstring(el)
            name = char(el);
        elseif isnumeric(el) && isscalar(el)
            t = get_param(el, 'Type');
            switch t
                case 'block'
                    name = getfullname(el);
                case 'block_diagram'
                    name = get_param(el, 'Name');
                otherwise
                    n = '';
                    try
                        n = get_param(el, 'Name');
                    catch
                    end
                    name = sprintf('%s/<%s %s>', get_param(el, 'Parent'), t, n);
            end
        elseif isobject(el) && isprop(el, 'Path')
            name = [el.Path '/' el.Name];
        else
            name = class(el);
        end
    catch
        name = '<unknown element>';
    end
end

function printSummary(e)
    skips = strcmp(e.kind, 'skip');
    notes = strcmp(e.kind, 'note');
    if ~any(skips)
        fprintf('SMOKE: all transformations applied.');
    else
        fprintf('SMOKE: %d transformation(s) could not be applied; those elements are unchanged.\n', sum(skips));
        [rules, ~, ix] = unique(e.rule(skips));
        counts = accumarray(ix, 1);
        [counts, order] = sort(counts, 'descend');
        for k = 1:numel(order)
            fprintf('   %5d  %s\n', counts(k), rules{order(k)});
        end
        fprintf('SMOKE: inspect them with  t = smokeLog(''report'')  (columns: rule, element, detail, identifier, message).');
    end
    if any(notes)
        fprintf('  %d note(s) in the report.', sum(notes));
    end
    fprintf('\n');
end
