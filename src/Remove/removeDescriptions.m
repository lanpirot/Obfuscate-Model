function removeDescriptions(elements)
% REMOVEDESCRIPTIONS Clear the Description and Tag of all ELEMENTS
% (blocks, lines, annotations).
    params = {'Description', 'Tag'};
    for i = 1:numel(elements)
        e = elements(i);
        for p = 1:numel(params)
            try
                value = get_param(e, params{p});
            catch
                continue % element has no such parameter
            end
            if isempty(value)
                continue
            end
            try
                set_param(e, params{p}, '');
            catch ME
                smokeLog('skip', 'removeDescriptions', e, ME, params{p});
            end
        end
    end
end
