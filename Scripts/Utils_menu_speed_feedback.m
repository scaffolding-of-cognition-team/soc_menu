%% Test how the transitions were on the menu
% The goal of this script is to give concrete feedback on the speed of transitions for a menu DJ. This can be used to train a DJ will testing without a participant or it can be used on real participant data
% The script takes in a mat file and then reads through the RunOrder (plus a few other places) to find the duration it takes to transition between experiments
% It then reports the summary of these transitions, separated by whether it was a transition from PlayVideo (indicating a burn in) vs within experiment (presumably the scanner is running)
% It also reports if there were mistakes in the transitions by seeing whether an experiment was quit out quickly
% Although the script does its best to accurately sort transitions into ones that are vs are not timed, it is falliable, and could label something a bad transition when it was actually fine. 
% For instance, if we need to reach in to adjust the camera during a transition then that would look like a slow transition but was not.
% 

function transition_summary = Utils_menu_speed_feedback(ppt_name)

short_block_threshold = 5; % How many seconds is the threshold for a short block that you quit out of
long_transition_threshold = 20; % How many seconds is the threshold for a transition before it is considered so slow it likely was normal
TR_duration = 2; % How long is the TR

ppt_file = sprintf('../Data/%s.mat', ppt_name);

if ~exist(ppt_file, 'file')
    error('The file %s does not exist. Quitting', ppt_file);
    return
end

% Load in the data
load(ppt_file);

% Check if the data has the correct structure
if isfield(Data, 'Global') == 0 || isfield(Data.Global, 'RunOrder') == 0 || isfield(Data.Global, 'Timing') == 0 || isfield(Data.Global.Timing, 'TR') == 0
    error('The file %s does not have the correct data structure. Quitting', ppt_file);
    return
end

% Get the run order
RunOrder = Data.Global.RunOrder;
TRs = Data.Global.Timing.TR;

% Get the meaning for what each code represents
Codes.PlayVideo_2_Experiment_scanner_off = 1;
Codes.PlayVideo_2_Experiment_scanner_on = -1;
Codes.Experiment_2_Experiment_scanner_off = 2; % This is a strange situation but could happen, e.g., eye tracker to eye tracker blocks. It is listed because it represents a time when nothing is on the screen and is thus bad
Codes.Experiment_2_Experiment_scanner_on = -2;

% How long should each transition take? (Build in a little tolerance due to the timing of TRs)
Transition_goals.PlayVideo_2_Experiment_scanner_off = 2; % This is a goal, saying that you spend less than 2s in the menu
Transition_goals.PlayVideo_2_Experiment_scanner_on = 6.5; % Can be 6-8 depending on whether you get lucky with the TR timing
Transition_goals.Experiment_2_Experiment_scanner_off = 2; % This is a goal, saying that you spend less than 2s in the menu
Transition_goals.Experiment_2_Experiment_scanner_on = 8.5; % Can be 6-8 depending on whether you get lucky with the TR timing

PlayVideo_end_time = 0;
transition_duration = [];
transition_type = []; 
transition_errors = [];
transition_blocks = [];
previous_experiment_end_time = 0;

% Loop through the rows of the run order
blockcounter = 1;
while blockcounter < size(RunOrder, 1)
    
    % Get the current experiment name
    ExperimentName = RunOrder{blockcounter, 1};
    
    % Get the block duration
    block_duration = RunOrder{blockcounter, 6} - RunOrder{blockcounter, 4};

    % Check if this block was short and if so, record it as an error
    if block_duration < short_block_threshold
        transition_errors(end + 1) = blockcounter;
    end

    if strcmp(ExperimentName, 'Experiment_PlayVideo')
       
        % Get the end of the PlayVideo
        PlayVideo_end_time = RunOrder{blockcounter, 6};
        
    else

        % Check if there was a transition error to decide whether to keep counting
        if block_duration >= short_block_threshold
            % Get the start and end of the Experiment
            Experiment_start_time = RunOrder{blockcounter, 4}; 
            
            % Store the experiment depending on whether it was a transition from PlayVideo (in which case the timing is >0) or another experiment
            if PlayVideo_end_time > 0
                previous_block_end_time = PlayVideo_end_time;
                transition_type(end + 1) = 1; % PlayVideo to experiment transition
            else
                previous_block_end_time = previous_experiment_end_time;
                transition_type(end + 1) = 2; % Experiment to experiment transition
            end
            
            transition_duration(end + 1) = Experiment_start_time - previous_block_end_time;

            % Check if there were any TRs within a short window after the previous block end time, suggesting that the scanner is still running
            if any(TRs > previous_block_end_time & TRs < previous_block_end_time + (TR_duration * 1.5) & TRs < Experiment_start_time)
                transition_type(end) = transition_type(end) * -1; % Make it a negative number to indicate the transition type
            end

            % If this was a really long transition then assume that it was a leisurely transition and not one we were trying to speed through
            if transition_duration(end) > long_transition_threshold
                transition_type(end) = 3;
            end

            transition_blocks(end + 1) = blockcounter;

            % Update the previous experiment end time
            previous_experiment_end_time = RunOrder{blockcounter, 6};

            % Reset to zero
            PlayVideo_end_time = 0;
        end

    end

    % Increment
    blockcounter = blockcounter + 1;

end

% Report the errors made in transitions, including by stating what blocks the error was made between
if ~isempty(transition_errors)
    for errorcounter = 1:length(transition_errors)
        
        if transition_errors(errorcounter) == 1
            warning('Transition error on the first run %s', RunOrder{1});
            continue
        end

        % What are the block idxs
        past_expt = RunOrder{transition_errors(errorcounter) - 1, 1};
        curr_expt = RunOrder{transition_errors(errorcounter), 1};
        next_expt = RunOrder{transition_errors(errorcounter) + 1, 1};
        past_block = RunOrder{transition_errors(errorcounter) - 1, 2};
        curr_block = RunOrder{transition_errors(errorcounter), 2};
        next_block = RunOrder{transition_errors(errorcounter) + 1, 2};

        % Get the duration of the transition
        transition_idx = transition_blocks == transition_errors(errorcounter) + 1; % What is the index of the end block of the transition?
        
        % If the tranistion type is 3 then ignore this, since errors are fine on these transitions
        if transition_type(transition_idx) ~= 3
            fprintf('\n######################\nError in transition (transition_duration=%0.2fs).\nStart: %s.%s\nError: %s.%s\nEnd: %s.%s\n\n', transition_duration(transition_idx), past_expt, past_block, curr_expt, curr_block, next_expt, next_block);
        end
    end
end

% Report information about the transitions
for transition_type_counter = [1, -1, 2, -2] % What transitions do you want to report on?

    % Find the name of the transition in the transition code section
    for fieldname = fieldnames(Codes)'
        if Codes.(fieldname{1}) == transition_type_counter
            transition_name = fieldname{1};
        end
    end

    % What is the goal duration of the transition
    transition_goal = Transition_goals.(transition_name);

    % Get all the transitions of this type
    transitions = transition_duration(transition_type == transition_type_counter);

    % Report the information about the transition
    if sum(transition_type == transition_type_counter) > 0     
        fprintf('\n######################\nTransition type:\n\t%s (goal: %0.1fs)\n######################\n', transition_name, transition_goal);

        fprintf('Median transition time: %0.2f\n', median(transitions));
        fprintf('Max transition time: %0.2f\n', max(transitions));
        fprintf('Min transition time: %0.2f\n', min(transitions));
        fprintf('Number of transitions: %d\n', length(transitions));
        
        % Check if any transitions are slower than the goal
        if any(transitions > transition_goal)

            % Report the slow transitions
            for transition_counter = 1:length(transition_duration)
                if (transition_duration(transition_counter) > transition_goal) && (transition_type(transition_counter) == transition_type_counter)

                    % What are the block idxs
                    past_expt = RunOrder{transition_blocks(transition_counter) - 1, 1};
                    curr_expt = RunOrder{transition_blocks(transition_counter), 1};
                    past_block = RunOrder{transition_blocks(transition_counter) - 1, 2};
                    curr_block = RunOrder{transition_blocks(transition_counter), 2};
                    
                    % If the tranistion type is 3 then ignore this, since errors are fine on these transitions
                    warning('Slow transition from %s.%s to %s.%s (%0.2fs)', past_expt, past_block, curr_expt, curr_block, transition_duration(transition_counter));
                    
                end
            end

        end
    end
end

% Store the information in a struct
transition_summary = struct('transition_duration', transition_duration, 'transition_type', transition_type, 'transition_errors', transition_errors, 'transition_blocks', transition_blocks);
transition_summary.RunOrder = RunOrder;

end