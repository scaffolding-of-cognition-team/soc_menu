%% Generate Trial sequence and conditions for Project Simsom images experiment
%
% Generate the appropriate trial sequence with randomization for a number of
% blocks in the Simsom experiment
%
% Adapted from FaceSpace code
%

function TrialStructure=GenerateTrials_Simsom_images(varargin)

%% Set up the parameters of the experiment

if length(varargin) >=3 && isfield(varargin{3},'Global') && isfield(varargin{3}.Global, 'SubjectID')
    SubjectID = varargin{3}.Global.SubjectID;
else
    SubjectID = '';
end

split_str = strsplit(SubjectID, '_');

if length(split_str) >= 2
    Base_SubjectID = strjoin(split_str(1:end-1),'_');
else
    Base_SubjectID = SubjectID;
end 
Parameters.Subject_stimulus_set = containers.Map();
Parameters.Subject_stimulus_set('ps_MRI_i01') = 'ps_MRI_i01';
Parameters.Subject_stimulus_set('ps_MRI_i02') = 'ps_MRI_i02';
Parameters.Subject_stimulus_set('ps_MRI_i03') = 'ps_MRI_i03';

Default_stimulus_set = 'ps_MRI_i01';

if length(Base_SubjectID) >=8 && strcmp(Base_SubjectID(1:8), 'ps_MRI_a')
    Stimulus_set_lookup_ID = ['ps_MRI_i', Base_SubjectID(9:end)];
else
    Stimulus_set_lookup_ID = Base_SubjectID;
end 

if isKey(Parameters.Subject_stimulus_set, Stimulus_set_lookup_ID)
    Chosen_stimulus_set = Parameters.Subject_stimulus_set(Stimulus_set_lookup_ID);
else
    warning('SubjectID "%s" not found. Using default set "%s"', Base_SubjectID, Default_stimulus_set);
    Chosen_stimulus_set = Default_stimulus_set; 
end 

fprintf('Using stimulus set "%s" for SubjectID "%s"\n', Chosen_stimulus_set, Base_SubjectID)

Parameters.Images_dir=['../Stimuli/Simsom/', Chosen_stimulus_set, '/']; %Where are the stimuli stored?

Parameter.Categories = {'Faces', 'Objects', 'Scenes'}; % What are the stimulus folders called

Parameters.DecayTime = 6; %How many seconds will you wait between blocks of the same run

Parameters.BlockNum = 1; %How many blocks are there in this experiment
%Parameters.BlockNames = {'Short_ISI', 'Long_ISI', 'Long_ISI_without_background'}; % What name do you want for this block?

Parameters.BlockNames = {'Short_ISI_with_background'}; % 'Short_ISI_without_background', 

% Shuffle the blocks so that they are always in a different order
Parameters.BlockNames = Shuffle(Parameters.BlockNames);

% How many repetitions of each stimulus do you want to do?
Parameters.Stim_repetitions = 2;

% Set the ISI and background information for each of the block types
Parameters.Block_parameters.Short_ISI_with_background.ISI = [1, 2];
Parameters.Block_parameters.Short_ISI_with_background.is_background = 1;
Parameters.Block_parameters.Short_ISI_with_background.ImageTime = 2.5;
Parameters.Block_parameters.Short_ISI_with_background.is_looming = 1;

Parameters.Block_parameters.Short_ISI_without_background.ISI = [1, 2];
Parameters.Block_parameters.Short_ISI_without_background.is_background = 0;
Parameters.Block_parameters.Short_ISI_without_background.ImageTime = 2.5;
Parameters.Block_parameters.Short_ISI_without_background.is_looming = 1;

% Parameters.Block_parameters.Long_ISI.ISI = [3.5, 4.5];
% Parameters.Block_parameters.Long_ISI.is_background = 1;
% Parameters.Block_parameters.Long_ISI.ImageTime = 3;
% Parameters.Block_parameters.Long_ISI.is_looming = 0;

% Parameters.Block_parameters.Long_ISI_without_background.ISI = [3.5, 4.5];
% Parameters.Block_parameters.Long_ISI_without_background.is_background = 0;
% Parameters.Block_parameters.Long_ISI_without_background.ImageTime = 2.5;
% Parameters.Block_parameters.Long_ISI_without_background.is_looming = 1;

Parameters.GIFRect_size = 40; % How many degrees wide is the gif
Parameters.BackgroundImagesDirectory='../Stimuli/GifFrames/';
Temp=dir(Parameters.BackgroundImagesDirectory);
Temp=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
Temp = Temp(arrayfun(@(x) ~strcmp(x.name(1:4),'Icon'),Temp));
for FileCounter=1:length(Temp)
    Stimuli.GifFiles{FileCounter}=Temp(FileCounter).name; %Store all the appropriate names
end    

% Get the music files to be randomly chosen for the Simsom_Images
% experiment
music_folder = ['../Stimuli/Simsom/', Chosen_stimulus_set, '/Music/'];

Parameters.Music_files = {};
temp_files = dir(music_folder);
for file_counter = 1:length(temp_files)
    file_name = temp_files(file_counter).name;
    if strcmp(file_name(1), '.') == 0
        Parameters.Music_files{end + 1} = [music_folder, file_name];
    end
end


%% Pull out all the stimuli

% Flatten the randomized groups into a single array for trial sequencing
Stimuli.Faces_files = {}; % Initialize or clear existing array
Stimuli.Objects_files = {}; % Initialize or clear existing array
Stimuli.Scenes_files = {}; % Initialize or clear existing array
for category = Parameter.Categories
    
    % Get the files for this category
    files = dir(fullfile(Parameters.Images_dir, category{1}, '*.png'));
    files = files(arrayfun(@(x) ~strcmp(x.name(1),'.'), files)); % Filter out hidden files


    % Scene images have a number appended to the end of them to indicate
    % what epoch of the photoshoot they are with the number style of XX. We only want the most recent
    % number. Any image that ends with 00 will always be used
    if strcmp(category{1}, 'Scenes')
        highest_epoch_number = 0; % Find 
        for file_counter = 1:length(files)
            
            % Get the file name
            file = files(file_counter).name;
            
            % Check that the relevant digits are numbers
            if isnan(str2double(file(end-5:end-4)))
                warning('Scene images are named wrong. File %s should have a number at the end of the name but instead it has %s. Quitting', file, file(end-5:end-4));
                TrialStructure = [];
                return
            end

            % Convert this to a number
            curr_epoch_number = str2num(file(end-5:end-4));
    
            % test if it is a greater number than the existing epoch counter
            if curr_epoch_number > highest_epoch_number 
                highest_epoch_number = curr_epoch_number;
                example_file = file;
            end
        end

        % Report the epoch chosen
        fprintf('Chosen epoch %02d for Scenes (e.g., %s)\n', highest_epoch_number, example_file);
    end
    
    % Store each file
    for file_counter = 1:length(files)
        
        % What is the file name?
        file = fullfile(Parameters.Images_dir, category{1}, files(file_counter).name);

        % Check if the images are of the correct epoch
        if strcmp(category{1}, 'Scenes')
            curr_epoch_number = str2num(file(end-5:end-4));
            
            % If the current epoch number is not what we are looking for
            % then don't use this image. If the current epoch number is 0,
            % this is ignored. That way you dont have to update numbers for
            % images that don't change
            if (curr_epoch_number) > 0 && (curr_epoch_number ~= highest_epoch_number)
                continue;
            end
        end
    
        % Add the file to the list
        Stimuli.(sprintf('%s_files', category{1})){end+1} = file;
        
    end
end

% Check that the number of stimuli is equal across conditions
if length(Stimuli.Faces_files) ~= length(Stimuli.Scenes_files) || length(Stimuli.Faces_files) ~= length(Stimuli.Objects_files)
    warning('Number of items found is inconsistent across categories. This is likely because Scenes were mislabelled (found %d scene images). Quitting', length(Stimuli.Scenes_files));
    TrialStructure = [];
    return
end

%% Store the outputs

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
