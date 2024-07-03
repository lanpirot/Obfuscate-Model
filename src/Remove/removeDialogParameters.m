function removeDialogParameters(sys)
% Reset all Dialog Parameters of all blocks
%
%   Inputs:
%       sys     Name of Simulink model or subsystem.
%
%   Outputs:
%       N/A
%
%   Side Effects:
%       Resets all Dialog Parameters of all blocks.

    block = find_system(sys, 'FindAll', 'on', 'FollowLinks', 'on', 'type', 'block');
    for i = 1:length(block)
        % create a tmp block from which to steal the default parameter values
        try
            curr_block = block(i);

            if strcmp(get_param(curr_block, 'parent'), 'Record_accelerometer/Navigation Subsystem/Calculate Gravity Vector/Accelerometer Neutral Gain and Offset') && strcmp(get_param(curr_block, 'name'), 'Mux')
                disp(1)
            end

            curr_parent = get_param(curr_block, 'Parent');
            tmp_block_path = [curr_parent '/' 'tmpblock'];
            tmp_block = add_block(['built-in/', get_param(curr_block, 'BlockType')], tmp_block_path);
            
            params = fields(get_param(tmp_block, 'DialogParameters'));
            for p = 1:length(params)
                if ismember(params{1}, {'Inputs', 'Outputs'}) %don't ruin mux/demux ports and their lines
                    continue
                end
                try
                    set_param(curr_block, params{p}, get_param(tmp_block, params{p}))
                catch ME
                end
            end
        catch ME
        end

        % Clean up: Remove tmp block
        try
            delete_block(tmp_block_path)
        catch ME
        end
        
    end
end