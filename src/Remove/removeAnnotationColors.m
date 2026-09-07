function removeAnnotationColors(annotations)
% REMOVEANNOTATIONCOLORS Reset the colors of all ANNOTATIONS to the defaults.
    for i = 1:numel(annotations)
        a = annotations(i);
        try
            if ~strcmp(get_param(a, 'ForegroundColor'), 'black')
                set_param(a, 'ForegroundColor', 'black');
            end
            if ~strcmp(get_param(a, 'BackgroundColor'), 'white')
                set_param(a, 'BackgroundColor', 'white');
            end
        catch ME
            smokeLog('skip', 'removeAnnotationColors', a, ME);
        end
    end
end
