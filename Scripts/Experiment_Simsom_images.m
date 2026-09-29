% Run a block of the Project Simsom Images experiment.
%
% Looming images are presented. The images change when at the smallest
% size. Different images are presented depending on the conditions fed in.
%
% Adapted from the FaceSpace code

% NOTE: TRs are not being collected during the menu prompting to choose a block for a yoked participant. 

function Data=Experiment_Simsom_images(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
Data_all=varargin{4};
    
% Get the block type
BlockName = Conditions.Parameters.BlockNames{ChosenBlock};

fprintf('\nSimsom Images\n\n');
fprintf('Block: %s\n', BlockName);

%% Set the random seed. For instants this will be set 'randomly' based on the clock. For adults this will be retrieved from the relevant infant session
if (length(Data_all.Global.SubjectID) >= 8) && strcmp(Data_all.Global.SubjectID(1:8), 'ps_MRI_i')
    % Get the seed based on the clock time
    seed = sum(100*clock);
    fprintf('New seed for an infant: %0.1f\n', seed);

elseif (length(Data_all.Global.SubjectID) >= 8) && strcmp(Data_all.Global.SubjectID(1:8), 'ps_MRI_a')
    % Pull out the session number for this participant
    split_str = strsplit(Data_all.Global.SubjectID, '_');
    session_number = split_str{4};

    % Find the corresponding adult name for the infant name
    adult_number = split_str{3}(2:end);
    
    % Find the infant session matching this adult session number
    infant_file = sprintf('../Data/ps_MRI_i%s_%s.mat', adult_number, session_number);


    % Does this infant_name file exist
    if exist(infant_file, 'file') == 2
        % Load the infant file
        infant_data = load(infant_file, 'Data');

        % For each block of Simsom images in the file, get the number of trials completed and report ir
        fprintf('Found infant file %s\n', infant_file);
        if isfield(infant_data.Data, 'Experiment_Simsom_images')
            fprintf('The following blocks are available to be yoked to (press q to quit):\n');
            
            % Loop through all the blocks run
            blocks_run = fieldnames(infant_data.Data.Experiment_Simsom_images);
            for block_counter = 1:length(blocks_run)
                if isfield(infant_data.Data.Experiment_Simsom_images.(blocks_run{block_counter}), 'Stimuli')
                    fprintf('%d. %s: %d trials\n', block_counter, blocks_run{block_counter}, length(infant_data.Data.Experiment_Simsom_images.(blocks_run{block_counter}).Stimuli.Name)); 
                else 
                    fprintf('%d. %s: 0 trials\n', block_counter, blocks_run{block_counter}); 
                end

            end

           
            
            % If they select 0 then the seed will be based on the clock
            fprintf('0. New seed\n\n');

            % Listen for a key press
            ChosenBlock = -1;
            while 1
                % Get the key code
                [~, keyCode] = KbQueueCheck(Window.KeyboardNum);
                
                % Has only one key been pressed?
                if sum(keyCode > 0) == 1
                    
                    selected_key = KbName(find(keyCode > 0));
                    selected_key = selected_key(1); % Get the first key pressed (since numeric presses are associated with 2 characters often)

                    % Loop through the valid codes
                    for valid_code = 0:length(blocks_run)
                        if strcmp(selected_key, num2str(valid_code)) > 0
                            ChosenBlock = valid_code;
                        elseif strcmp(selected_key, 'q')
                            warning('Quitting the experiment');
                            Data.Quit = 1;
                            Data.Timing.DecayLapse=GetSecs;
                            Data.Timing.TR = [];
                            return
                        end
                    end
                    
                    % Break if a selection has been made
                    if ChosenBlock ~= -1
                        break
                    else
                        fprintf('%s is invalid. Please select a valid block\n', KbName(find(keyCode > 0)));
                        pause(0.1); % Add a pause to stop a lot of outputs
                    end
                end
            end
            
            % Report the selection
            if ChosenBlock == 0
                fprintf('Chosen to make a new seed\n');
            else
                fprintf('Chosen block: %s\n', blocks_run{ChosenBlock});
            end

            % Use the code they selected to pull out the seed
            if ChosenBlock == 0
                seed = sum(100*clock);
            else
                % Get the seed from the infant file
                seed = infant_data.Data.Experiment_Simsom_images.(blocks_run{ChosenBlock}).seed;
            end

        else
            warning(sprintf('Could not find the Simsom images in the infant file. This means that this data will not be yoked. Do you want to continue? Press any key if so, otherwise press ''q'' twice quickly.', infant_file));
            KbQueueWait(Window.KeyboardNum);
            seed = sum(100*clock);
        end

        fprintf('Seed for an adult: %0.1f\n', seed);
    else
        % Get the seed based on the clock time
        seed = sum(100*clock);
        
        % If there is no infant file then issue a warning and wait for a key press
        warning(sprintf('Could not find %s. This means that this data will not be yoked. Do you want to continue? Press any key if so, otherwise press ''q'' twice quickly.', infant_file));
        KbQueueWait(Window.KeyboardNum);

        fprintf('\nNew seed for an adult: %0.1f\n', seed);
    end

else
    % Get the seed based on the clock time
    seed = sum(100*clock);
    fprintf('New seed for a test: %0.1f\n', seed);
end

% Set the seed
rng(seed);

% Store the seed
Data.seed = seed;

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

%% Set the parameter conditions

%Set stimulus size
InitialImageSize=0; %How wide in visual degrees do you want the image to be before transformation?
EndImageSize=30; %How tall in visual degrees do you want the image to end up?

% Get the parameters for this block
Block_parameters = Conditions.Parameters.Block_parameters.(BlockName);

%Set timing
SmallImageTime=0; 
ImageTime=Block_parameters.ImageTime; %How many seconds for the image to be presented
if Block_parameters.is_looming == 1
    LoomingTime=0.25; %How many seconds for the image to enlarge. If it isn't looming then this will be ignored
else
    LoomingTime=0; % Set to zero if not looming
end

%Set how the looming works
LoomingType='Exponential'; %How do you want looming to work? Can be 'linear', 'exponential' or 'quadratic'
Monotonic=0; %Is it just looming or does it also contract?

% Do you want to convert the alpha channel to be white?
is_background_white = 1;

% platform-independent responses
KbName('UnifyKeyNames');
flipTime = Screen('GetFlipInterval',Window.onScreen);

%Specify some screen attributes
screenX = Window.screenX;
screenY = Window.screenY;
centerX = Window.centerX;
centerY = Window.centerY;

% Randomise the order of the stimuli
% Create a vector of numbers (1-3) representing the categories without any back to back repeats
total_images = sum([length(Conditions.Stimuli.Faces_files), length(Conditions.Stimuli.Objects_files), length(Conditions.Stimuli.Scenes_files)]);
total_trials = total_images * Conditions.Parameters.Stim_repetitions;

category_sequence_repeats = {};
category_sequence_all = [];
for repetition_counter = 1:Conditions.Parameters.Stim_repetitions % Loop through this as many repetitions as you need
    
    non_matches = inf;
    category_sequence = [];
    while length(category_sequence) < total_images
    
        % If there are too many non-matches then reset the loop. Start on a non match so as to reset the loop
        if non_matches > 10
            %fprintf('Resetting the sequence\n');
            non_matches = 0;
    
            category_available = [length(Conditions.Stimuli.Faces_files), length(Conditions.Stimuli.Objects_files), length(Conditions.Stimuli.Scenes_files)];
            
            % If this is the first run, just pick a random start. If it is
            % not the first run, make sure that it isnt the same as the
            % previous trial
            if repetition_counter == 1
                category_sequence = randi(3); % Pick a random starting category
            else
                previous_category = category_sequence_all(end); % Get last trial
                category_options = setdiff(1:3, previous_category); % Remove this last category as an option
                category_options = Shuffle(category_options);
                category_sequence = category_options(1); % Get the randomly selected first

            end


            category_available(category_sequence) = category_available(category_sequence) - 1; % Remove the category from the available list
        end
    
        current_options = [repmat(1, 1, category_available(1)), repmat(2, 1, category_available(2)), repmat(3, 1, category_available(3))];
    
        current_options = Shuffle(current_options); % Shuffle them in place
        proposed_option = current_options(1);
    
        % If this one does not match the last one then add it to the sequence
        if proposed_option ~= category_sequence(end)
            category_sequence = [category_sequence, proposed_option];
            category_available(proposed_option) = category_available(proposed_option) - 1;
            non_matches = 0; % Reset the non-matches
        else
            % Count the number of non-matches
            non_matches = non_matches + 1;
        end
    
    end
    
    % Combine the information across repetitions
    category_sequence_repeats{end + 1} = category_sequence;
    category_sequence_all = [category_sequence_all, category_sequence];
end

% % Compute the time between trials of the same category
% events_between_categories = [];
% for i = 1:length(category_sequence_all)-1
%     next_trial = find(category_sequence_all(i+1:end) == category_sequence_all(i), 1);
%     if ~isempty(next_trial)
%         events_between_categories(end + 1) = next_trial;
%     end
% end
% average_trial_duration=(LoomingTime * 2)+ ImageTime + SmallImageTime + mean(Block_parameters.ISI);
% fprintf('Average SOA between trials: %0.1f\n', average_trial_duration * mean(events_between_categories));

% Create the sequence of stimuli
Stimulus_sequence = {};
categories = {'Face', 'Object', 'Scene'};

% Repeat the sequences as mentioned
for repetitions = 1:Conditions.Parameters.Stim_repetitions

    % Randomize the stimuli so that they are in a unique order
    Face_files = Shuffle(Conditions.Stimuli.Faces_files);
    Object_files = Shuffle(Conditions.Stimuli.Objects_files);
    Scene_files = Shuffle(Conditions.Stimuli.Scenes_files);

    for i = 1:length(category_sequence_repeats{repetitions})

        % What category is it for this trial
        switch category_sequence_repeats{repetitions}(i)
            case 1
                Stimulus_sequence{end + 1} = Face_files{1};
                Face_files = Face_files(2:end); % Trim this file from the list
            case 2
                Stimulus_sequence{end + 1} = Object_files{1};
                Object_files = Object_files(2:end); % Trim this file from the list
            case 3
                Stimulus_sequence{end + 1} = Scene_files{1};
                Scene_files = Scene_files(2:end); % Trim this file from the list
        end
    end
end

% Set up the ISI order
ISI_sequence = (rand(1, length(Stimulus_sequence)) * (Block_parameters.ISI(2) - Block_parameters.ISI(1))) + Block_parameters.ISI(1); % What is the IS for this trial?

%If the size is input as 0 then make it a 1 pixel sized image
if InitialImageSize<=0
    InitialImage_ppd=1;
else
    InitialImage_ppd=InitialImageSize*Window.ppd;
end

EndImage_ppd=EndImageSize*Window.ppd/2;

NumofLoomingFrames=round(LoomingTime/flipTime)-1; %Subtract one because you need a spare frame at the end 

%What are the size increases
if strcmp(LoomingType, 'Linear')
    
    %Make linear increments
    SizeIncrements=InitialImage_ppd:((EndImage_ppd-InitialImage_ppd)/NumofLoomingFrames): EndImage_ppd;

elseif strcmp(LoomingType, 'Exponential')
    
    %Find the exponents that are the start and the end
    StartingExp=log(InitialImage_ppd)/log(2);
    EndingExp=log(EndImage_ppd)/log(2);
    
    SizeIncrements=2.^(StartingExp:((EndingExp-StartingExp)/NumofLoomingFrames):EndingExp);
    
elseif strcmp(LoomingType, 'Quadratic')
    
    %Get the necessary features of the sigmoid plot
    Sequence=(0:NumofLoomingFrames)-(NumofLoomingFrames/2); %find the list of values
    Max=EndImage_ppd; %What is the ending value
    Min=InitialImage_ppd; %What is the starting value
    Slope=0.5; %Lower numbers mean steeper. Negative values flip it. This value was choosen so that there is some lead in where no change happens but will vary depending on the looming time
    
    %Make the sigmoid representing the value changes
    SizeIncrements=((Max-Min)./(1+exp(-1*Slope*Sequence))) + Min;
end

SizeIncrements=SizeIncrements(1:end); %Erase the start point (the end point is likely to be a little short due to rounding)

Reversed_SizeIncrements=fliplr(SizeIncrements); %Flip the sequence of the items

%Translate the timing of the experiment into appropriate amounts for the
%flipTime.

Data.Timing.SmallImageTime=round(SmallImageTime/flipTime)*flipTime;
Data.Timing.LoomingTime=round(LoomingTime/flipTime)*flipTime;
Data.Timing.ImageTime=round(ImageTime/flipTime)*flipTime;

%% Load in the GIF
for GifCounter=1:length(Conditions.Stimuli.GifFiles)
    
    FileList = Conditions.Stimuli.GifFiles; % Pull out the filenames
    
    %Get the path for the given file
    iImageName=[Conditions.Parameters.BackgroundImagesDirectory, '/' FileList{GifCounter}];
    
    %Set up the image
    iImage=imread(iImageName);
    
    BackgroundTexs(GifCounter)=Screen('MakeTexture', Window.onScreen, iImage);
end

% Define the size of the GIF
GIFRect_size = Conditions.Parameters.GIFRect_size;
GIFRect_ppd = GIFRect_size * Window.ppd / 2;
GIFRect = [centerX-GIFRect_ppd,centerY-GIFRect_ppd,centerX+GIFRect_ppd,centerY+GIFRect_ppd];

% Load in the audio object
play_audio = 0;
if length(Conditions.Parameters.Music_files) > 0
    play_audio = 1;
    music_files = Shuffle(Conditions.Parameters.Music_files);
    music_file = music_files{1};
    [music_wave, music_fs] = audioread(music_file);
    music_obj=audioplayer(music_wave, music_fs, 16); 
    
    fprintf('Playing %s', music_file);
    Data.Music_file = music_file;
end

%% Wait for the scanner

% If the scanner is running it will wait 1 TR to begin, if it is not
% running but could be then it will hang until a burn has completed. If
% there is no scanner connected then 

[Data.Timing.TR, Quit]=Setup_WaitingForScanner(Window);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));

%Calculate when is the next TR expected
if ~isempty(Data.Timing.TR)
    NextTR=Data.Timing.TR(end)+Window.TR;
else
    NextTR=Window.NextTR;
end

%% Begin experiments
if play_audio == 1
    play(music_obj);
end

%When does the test begin
Data.Timing.TestStart=GetSecs;
StimulusCounter=1;
GIF_change = 1;
GifCounter = 1;
BackgroundTex = BackgroundTexs(GifCounter); % What image of the GIF to show
while StimulusCounter <= length(Stimulus_sequence) && Quit==0
    
    %% ISI loop
    ISI = ISI_sequence(StimulusCounter); % What is the ISI for this trial?
    ISIOns_actual = inf; % First time the while loop is evaluated it is always true
    while (ISIOns_actual + ISI - flipTime)>GetSecs
        
        if GifCounter >= length(BackgroundTexs)
            GIF_change = -1;
        elseif GifCounter <= 1
            GIF_change = 1;
        end

        GifCounter = GifCounter + GIF_change;
        
        BackgroundTex = BackgroundTexs(GifCounter); % What image of the GIF to show

        Screen(Window.onScreen,'FillRect',Window.bcolor);
        if Block_parameters.is_background == 1
            Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
        end
        flipOns = Screen('Flip',Window.onScreen);

        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        
        %If they have pressed q then quit
        if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
            Quit=1;
        end
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
        end
        
        % If first flip, get the relevant info
        if ISIOns_actual == inf
            ISIOns_actual = flipOns;
        end
    end
    
    % If there was a quit during the ISI then do that now
    if Quit == 1
        break
    end


    %% Load the image for this trial
    iImageName=Stimulus_sequence{StimulusCounter}; %What texture to call
    category=categories{category_sequence_all(StimulusCounter)}; %What category is this image

    %Set up the image
    iImage=imread(iImageName);
    Alphachannel = [];
    if ~isempty(Alphachannel)
        iImage(:,:,4)=Alphachannel;
    end
    
    %If it is gray scale then you need to do this
    if length(size(iImage))==2
        iImage(:,:,2)=iImage(:,:,1);
        iImage(:,:,3)=iImage(:,:,1);
    end

    % Convert the alpha channel to white
    if is_background_white == 1
        R = iImage(:, :, 1);
        G = iImage(:, :, 2);
        B = iImage(:, :, 3);
        % Mask the channels by the alpha mask
        R(Alphachannel == 0) = 255;
        G(Alphachannel == 0) = 255;
        B(Alphachannel == 0) = 255;
        iImage =  cat(3, R, G, B); % Concatenate the channels
    end
    
    ImageTex=Screen('MakeTexture', Window.onScreen, iImage);

    ScalingFactor=size(iImage,2)/size(iImage,1); %How much bigger is the Y than the x of the image?
    
    InitialRect= [centerX-(InitialImage_ppd*ScalingFactor),centerY-InitialImage_ppd,centerX+(InitialImage_ppd*ScalingFactor),centerY+InitialImage_ppd];
    EndRect = [centerX-(EndImage_ppd*ScalingFactor),centerY-EndImage_ppd,centerX+(EndImage_ppd*ScalingFactor),centerY+EndImage_ppd];

    %Output the trial information
    fprintf('\n Trial: %d; Category: %s\nStimulus %s\nISI=%0.1f', StimulusCounter, category, iImageName, ISI);
    
    %% Loom the image in
    % Present the initial image
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    if Block_parameters.is_background == 1
        Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
    end
    Screen('DrawTexture', Window.onScreen, ImageTex, [], InitialRect); %Draw the image in the specified rect
    
    InitialImageOns_actual = Screen('Flip',Window.onScreen);
        
    % Start the eye tracker for this trial
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Trial_%d_Time:_%0.3f', StimulusCounter, InitialImageOns_actual));        
    Utils_EyeTracker_TrialStart(Window.EyeTracking);
    
    if SmallImageTime > 0

        %Wait until the stimulus is ready to loom
        if Block_parameters.is_background == 1
            Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
        end
        Screen('DrawTexture', Window.onScreen, ImageTex, [], InitialRect); %Draw the image in the specified rect
        
        while InitialImageOns_actual+Data.Timing.SmallImageTime-flipTime>GetSecs
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
        end
        LoomingOns_actual = Screen('Flip',Window.onScreen); 
    else
        LoomingOns_actual = InitialImageOns_actual;
    end
        
    Counter=1;
    while GetSecs<LoomingOns_actual+Data.Timing.LoomingTime -(flipTime) && (Data.Timing.LoomingTime > 0)
        
        % Only specify the size if you still have runway
        if Counter <= length(SizeIncrements)
            LoomingRect=[centerX-(SizeIncrements(Counter)*ScalingFactor),centerY-SizeIncrements(Counter),centerX+(SizeIncrements(Counter)*ScalingFactor),centerY+ SizeIncrements(Counter)];
        end

        %Clear screen
        if Block_parameters.is_background == 1
            Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
        end
        Screen('DrawTexture', Window.onScreen, ImageTex, [], LoomingRect); %Draw the image in the specified rect
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
         
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
        end
        
        LoomingOffs_actual=Screen('Flip',Window.onScreen); %Don't bother storing it
        
        Counter=Counter+1;
    end
    
    LoomingFlips=Counter-1; %How many flips were performed for the looming section. If it is not constant then you have an issue
    

    %% Present the stable image
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    if Block_parameters.is_background == 1
        Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
    end
    Screen('DrawTexture', Window.onScreen, ImageTex, [], EndRect); %Draw the image in the specified rect
    ImageOns_actual = Screen('Flip',Window.onScreen);

    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_of_Trial_%d_Time:_%0.3f', StimulusCounter, ImageOns_actual));        
        
    while GetSecs<ImageOns_actual+Data.Timing.ImageTime-flipTime && Quit==0
        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        
        %If they have pressed q then quit
        if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
            Quit=1;
        end
        
        %Check for trigger
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
        end
        
    end
    
    %% If it is appropriate then loom out
    if Monotonic==0 && Quit == 0

        Counter=1;
        ShrinkingOns_actual = inf; % Set to inf and correct later
        while GetSecs<ShrinkingOns_actual+Data.Timing.LoomingTime-flipTime && (Data.Timing.LoomingTime > 0) %Even though there is ITI you need this time
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
            end
            
            % Only specify the size if you still have runway
            if Counter <= length(SizeIncrements)
                LoomingRect=[centerX-(Reversed_SizeIncrements(Counter)*ScalingFactor),centerY-Reversed_SizeIncrements(Counter),centerX+(Reversed_SizeIncrements(Counter)*ScalingFactor),centerY+ Reversed_SizeIncrements(Counter)];
            end

            %Clear screen
            if Block_parameters.is_background == 1
                Screen('DrawTexture', Window.onScreen, BackgroundTex, [], GIFRect); 
            end
            Screen('DrawTexture', Window.onScreen, ImageTex, [], LoomingRect); %Draw the image in the specified rect
            
            %Check for trigger
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            % Determine what the time stamps are
            if ShrinkingOns_actual == inf
                ShrinkingOns_actual = Screen('Flip',Window.onScreen);
            else
                ShrinkingOffs_actual=Screen('Flip',Window.onScreen); %By saving it you will only keep the last one
            end
            Counter=Counter+1;
        end
        
        ShrinkingFlips=Counter-1; %How many flips were performed for the looming section. If it is not constant then you have an issue
        
        %Don't clear the screen if it is non-monotonic
        
    end
        

    if Quit==0
  
        % save stuff
        Data.Timing.ISIOns(StimulusCounter,:)=ISIOns_actual;
        Data.Timing.SmallImageOns(StimulusCounter,:)=InitialImageOns_actual;
        if Block_parameters.is_looming == 1
            Data.Timing.LoomingOns(StimulusCounter,:)=LoomingOns_actual;
            Data.Timing.LoomingFlips(StimulusCounter)=LoomingFlips;
            Data.Timing.LoomingOffs(StimulusCounter,:)=LoomingOffs_actual;
        end
        Data.Timing.ImageOns(StimulusCounter,:)=ImageOns_actual;
        
        if Monotonic==0 && Block_parameters.is_looming == 1
            Data.Timing.ShrinkingOns(StimulusCounter,:)=ShrinkingOns_actual;
            Data.Timing.ShrinkingFlips(StimulusCounter)=ShrinkingFlips;
            Data.Timing.ShrinkingOffs(StimulusCounter,:)=ShrinkingOffs_actual;
        end

        %Store what stimuli were presented
        Data.Stimuli.Name{StimulusCounter}=iImageName;
        Data.Stimuli.category{StimulusCounter}=category;

    end


    %Clear up the screens so that you don't store the irrelevant textures.
    Screen('Close', ImageTex)
    
    % Start the eye tracker for this trial
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Trial_%d_Time:_%0.3f', StimulusCounter, GetSecs));        
    Utils_EyeTracker_TrialEnd(Window.EyeTracking);

    StimulusCounter=StimulusCounter+1;
end

% End experiment flip
Screen(Window.onScreen,'FillRect',Window.bcolor);
Data.Timing.TestEnd = Screen('Flip',Window.onScreen);

% In case of quit
Utils_EyeTracker_TrialEnd(Window.EyeTracking); %trial end (for stimuli)

%Issue a quit message if not enough trials have been run
if Quit==1 && StimulusCounter < 10
    fprintf('\nBlock Terminated on Stimulus %d, not counting\n\n', StimulusCounter-1);
else
    % Make sure this doesn't get registered as a quit
    Quit = 0;
end

%Record whether this was quit preemptively
Data.Quit=Quit;

%Record the time at which the next experiment can start
Data.Timing.DecayLapse=Data.Timing.TestEnd+Conditions.Parameters.DecayTime;

%% pack up, go home...
for GifCounter=1:length(Conditions.Stimuli.GifFiles)
    Screen('Close', BackgroundTexs(GifCounter));
end

if play_audio == 1
    stop(music_obj);
end

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 

end

