function removeModelInformation(sys)
% REMOVEMODELINFORMATION Reset the model information found under
% Model Properties > Main and Model Properties > History. Some values
% (LastModifiedBy, LastModifiedDate, ModelVersion) only change when the model
% is saved.

    sys = get_param(sys, 'Handle');
    now = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    settings = {
        'ModifiedByFormat',   'user'
        'Creator',            'user'
        'Created',            now
        'ModifiedComment',    ''
        'ModifiedHistory',    ''
        'ModelVersionFormat', '1.0'
        'Description',        ''
        'ExtraOptions',       ''
        };
    for i = 1:size(settings, 1)
        try
            set_param(sys, settings{i, 1}, settings{i, 2});
        catch ME
            smokeLog('skip', 'removeModelInformation', sys, ME, settings{i, 1});
        end
    end
end
