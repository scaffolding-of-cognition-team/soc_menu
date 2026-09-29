%% Generate Trial sequence and conditions for the Play Video

%Generate the appropriate trial sequence with randomization for a number of
%blocks in the narrowing/localizer experiment

%C Ellis 9/25/15

function TrialStructure=GenerateTrials_PlayVideo(varargin)

Window = varargin{4};

%Set up the parameters of the experiment

Parameters.BaseExt=cd; %What is the current folder directory name
if ispc == 1
    Parameters.BaseExt=Parameters.BaseExt(1:max(find(Parameters.BaseExt=='\'))); %Remove the current folder
else
    Parameters.BaseExt=Parameters.BaseExt(1:max(find(Parameters.BaseExt=='/'))); %Remove the current folder
end

% Test whether you got a reasonable result
if isempty(Parameters.BaseExt)
    warning('Parameters.BaseExt is length zero, probably because your computer uses a different file system path than what is assumed');
end
    

Parameters.StimulusDirectory='../Stimuli/AttentionGrabberVideos/'; %Where are the stimuli stored?

Parameters.BlockNum=3; %These actually represent two modes of interacting with the experiment

%Save these names so they can be used in the menu. Remember blocks
%indicate different ways of interacting with the experiment
Parameters.BlockNames={'Movies resume from where most recently run', 'Movies restart every call', 'Wait for TRs at the start of the experiment'};

Parameters.WaitforTR=[0,0,1]; %On what blocks should you wait for a TR?

Parameters.Preload=0; %Would you like to preload the textures before playing the movie?

Parameters.isAnticipationError=0; %Don't receive responses
 
Parameters.DecayLapse=Window.BurnOut * Window.TR; %How many seconds will you wait for DecayLapse

%Specify the 4 values that define the rectangle of the movie. Here we are
%using the maximum display allowed while assuming the movie is 16:9
width = Window.DisplayRect(3) - Window.DisplayRect(1);
height = Window.DisplayRect(4) - Window.DisplayRect(2);

% Check if the width exceeds the ideal visual angle, if so reduce it down
ideal_visual_angle = 60; % Specify the ideal width in visual degrees
max_visual_angle = width / Window.ppd; % What is the max possible width of the screen
if max_visual_angle > ideal_visual_angle
    width = round(Window.ppd * ideal_visual_angle);
end

% Change the height or width depending on if it is too wide
if (width / height) > (16/9)
    width = height * (16/9);
else
    height = width * (9/16);
end

% Take the width and height from the center
movie_rect = round([Window.centerX - (width / 2), Window.centerY - (height / 2), Window.centerX + (width / 2), Window.centerY + (height / 2)]);

for block_counter = 1:Parameters.BlockNum
    Parameters.Rect{block_counter}=movie_rect;
end

% Get all of the files in this directory

Temp=dir(Parameters.StimulusDirectory); %What files are in the directory
DirNames=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
DirNames=DirNames(~[DirNames.isdir]); % Remove folders from the list

% If you don't have any files then download an example movie you could use
if length(DirNames) == 0
    PrintText_List={};
    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Could not find a movie file in %s. Instead downloading the open-source Big Buck Bunny (Blender studios) movie from the internet for use, Be aware, this movie might not be appropriate for young children.\n\nThis may take a few minutes (or may crash immediately if the link is broken or there is no internet connection) ....\n', Parameters.StimulusDirectory));
    
    % Make the directory if it doesn't exist
    if exist(Parameters.StimulusDirectory) == 0
        mkdir(Parameters.StimulusDirectory);
    end
    
    % Load the data
    try
        urlwrite('https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4', [Parameters.StimulusDirectory, 'BigBuckBunny.mp4'])
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Finished downloading\n'));
    catch
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Failed to load the data\n'));
    end
    
    % Refind what is contained in the stimulus folder
    Temp=dir(Parameters.StimulusDirectory); %What files are in the directory
    DirNames=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
    DirNames=DirNames(~[DirNames.isdir]); % Remove folders from the list
end


% Loop through the videos and store the names of the videos in the structure. 
for FileCounter=1:length(DirNames)
    
    %Store the movie names
    Stimuli.VideoNames{FileCounter}=[Parameters.StimulusDirectory, DirNames(FileCounter).name]; 
    
end

% Get the attention getter videos if they exist
AG_path=[Parameters.StimulusDirectory, 'AGs/']; % Where are the attention getters stored?
Stimuli.AGVideoNames = {};
if exist(AG_path) > 0 % Check if the directory exists
    AG_files = dir(AG_path); % Get the files in the directory
    AG_files = AG_files(arrayfun(@(x) ~strcmp(x.name(1),'.'), AG_files)); % Remove hidden files
    
    for i = 1:length(AG_files)
        Stimuli.AGVideoNames{i} = [AG_path, AG_files(i).name]; % Store the attention getter video names
    end
else
    Stimuli.AGVideoNames = {}; % If the directory doesn't exist, set it to an empty cell array
end



%Store these

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
