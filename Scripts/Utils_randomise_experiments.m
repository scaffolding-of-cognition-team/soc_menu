% Generate a random order of experiments that you should run this
% participant
%
% This ignores any files with hide or pilot as a suffix, as well as
% PlayVideo and EyeTrackerCalib. You can additionally ignore any others you
% wish by specifying them as inputs

function Utils_randomise_experiments(ignored_experiments)

if nargin<1
    ignored_experiments={};
end

% Check that ignored_experiments is a cell, otherwise return an error
if ~iscell(ignored_experiments)
    error('ignored_experiments must be a cell array');
end

% List the experiments that are ignored regardless of the input
baseline_ignored = {'PlayVideo', 'EyeTrackerCalib', 'RestingState'};

% Add the baseline ignored experiments to the list of ignored experiments
ignored_experiments = [ignored_experiments, baseline_ignored];

%Reset the shuffler, do it differently depending on the matlab version
Temp=version; %What version of matlab are you running?
if str2double(Temp(1))>=8
    rng('shuffle');
else
    rand('twister', sum(clock));
end

%% What are the possible programs that could be run. 
% This can be updated after a participant has been run with no consequence
Temp_Experiment=dir('Experiment_*.m');
ExperimentNames={};
for ExperimentCounter=1:length(Temp_Experiment)
     %Only include functions with pilot in the name when the participant is called pilot
    if logical(isempty(strfind(Temp_Experiment(ExperimentCounter).name, 'Pilot')) && isempty(strfind(Temp_Experiment(ExperimentCounter).name, 'Hide')))
        ExperimentNames(end+1)={Temp_Experiment(ExperimentCounter).name(1:end-2)};
    end
end

% Remove the ignored experiments
for i=1:length(ignored_experiments)
    
    % Where is this experiment in the list?
    exp_idx = strcmp(ExperimentNames, ['Experiment_', ignored_experiments{i}]);

    ExperimentNames(exp_idx)=[];
end

% Now that you have the list, randomise them
RandomisedOrder=randperm(length(ExperimentNames));
ExperimentNames=ExperimentNames(RandomisedOrder);

% Now print out the experiments nicely
fprintf('\n##############\nRandom experiment order:\n');
for ExperimentCounter=1:length(ExperimentNames)
    fprintf('%d: %s\n', ExperimentCounter, ExperimentNames{ExperimentCounter});
end
fprintf('##############\n\n');

end

