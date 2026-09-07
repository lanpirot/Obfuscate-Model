function new = neutralValue(old, kind)
% NEUTRALVALUE A replacement for OLD that is guaranteed to differ from it.
%
%   Sanitization must actually change a value. Resetting to a common default
%   like 0 or 1 often lands on the value the model already had, and the
%   sanitization would silently do nothing. SMOKE therefore uses the odd
%   value -17; if the value already is -17 (or 17), -19 is used instead.
%   Numbers stay numbers, numeric text stays text, quoted strings stay quoted.
%
%   neutralValue(3)       -> -17        neutralValue(-17)    -> -19
%   neutralValue('0.5')   -> '-17'      neutralValue('"ab"') -> '"-17"'
%   neutralValue('K*2')   -> '-17'      (variables and expressions too)
%   neutralValue('K', 'name') -> 'x17'  (where Simulink expects a name, an
%                                        identifier is needed; 'x19' if it
%                                        already is 'x17')

    if nargin > 1 && strcmp(kind, 'name')
        if any(strcmp(strtrim(char(old)), {'x17', 'x19'}))
            new = 'x19';
        else
            new = 'x17';
        end
        return
    end
    if isnumeric(old) || islogical(old)
        if isscalar(old) && any(old == [17 -17])
            new = -19;
        else
            new = -17;
        end
        return
    end
    old = strtrim(char(old));
    if startsWith(old, '"') || startsWith(old, '''')
        q = old(1);
        if any(strcmp(old, {[q '-17' q], [q '17' q]}))
            new = [q '-19' q];
        else
            new = [q '-17' q];
        end
    elseif any(strcmp(old, {'-17', '17'}))
        new = '-19';
    else
        new = '-17';
    end
end
