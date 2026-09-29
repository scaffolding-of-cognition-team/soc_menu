%% Show an image of a specific size in order to help with calibration 
%
% Specify the size of an image
%
%First draft 6/25/18 C Ellis

function Data=Experiment_ImDisplay_Pilot(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
%KbQueueFlush(Window.KeyboardNum);

fprintf('\n\nImage size.\n\n');

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));
    
%% Set the parameter conditions

%Set the parameters for the checkerboard
BlockSize = Window.ppd; % How many pixels in size is the image
fix_rad = 10; % How big is the fixation dot
vis_angle = 10;

BlocksAcross= ceil((Window.Rect(3) + BlockSize)/(BlockSize*2));
BlocksHigh= ceil((Window.Rect(4) + BlockSize)/(BlockSize*2));

%Generate the checkerboard
Temp=checkerboard(round(BlockSize), BlocksHigh + 1, BlocksAcross + 1);
Checkerboard_img=[];
Temp=Temp(round(size(Temp, 1)/2 - Window.centerY):round(size(Temp, 1)/2 + Window.centerY), round(size(Temp, 2)/2 - Window.centerX):round(size(Temp, 2)/2 + Window.centerX));

Checkerboard_img(:,:,1)=Temp; Checkerboard_img(:,:,2)=Temp; Checkerboard_img(:,:,3)=Temp; %Make a 3d mat

Checkerboard_img=uint8(Checkerboard_img*255);

% Load in the test display image
test_display_img = imread(Conditions.Stimuli.SelectedStimuli_Names);

% Resize so it is the same size
test_display_img=imresize(test_display_img, max(size(Checkerboard_img)) / max(size(test_display_img)));

% Crop the image so it is the same size
min_size = size(Checkerboard_img, 1); % Assume it is a widescreen display
midpoint = round(size(test_display_img, 2) / 2);
test_display_img = test_display_img(midpoint - floor(min_size / 2): midpoint + ceil(min_size / 2), :, :);

% Set this to the default
img = Checkerboard_img;

Quit=0;
Screen('TextSize',Window.onScreen, 24);
while Quit == 0
    
    % How big is the image
    Rect_size = vis_angle * Window.ppd;  % What is the size of the fixation stimulus

    %Generate a texture
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    ImageTex = Screen('MakeTexture', Window.onScreen, img);
   
    % Set the image size
    im_rect = [Window.centerX-(Rect_size/2), Window.centerY-(Rect_size/2), Window.centerX+(Rect_size/2), Window.centerY+(Rect_size/2)];
    
    % Constrain it to be no bigger than display rect
    if im_rect(1) < Window.DisplayRect(1)
        im_rect(1) =  Window.DisplayRect(1);
    end

    if im_rect(2) < Window.DisplayRect(2)
        im_rect(2) =  Window.DisplayRect(2);
    end

    if im_rect(3) > Window.DisplayRect(3)
        im_rect(3) =  Window.DisplayRect(3);
    end

        if im_rect(4) > Window.DisplayRect(4)
        im_rect(4) =  Window.DisplayRect(4);
    end



    %Draw the texture
    Screen('DrawTexture', Window.onScreen, ImageTex, im_rect);
    Screen('FillOval', Window.onScreen, uint8([255, 0, 0]), [Window.centerX-fix_rad, Window.centerY-fix_rad, Window.centerX+fix_rad, Window.centerY+fix_rad]);
    DrawFormattedText(Window.onScreen, sprintf('\nVisual angle: %0.2f\n Press up and down to increase size. Press ''s'' to switch between images', vis_angle), 'center', [], uint8([0,255,0]));
    
    %Flip the display
    Screen('Flip',Window.onScreen);
    
    % Did they press a key?
    [~, keyCode] = KbWait(Window.KeyboardNum);
    
    %If they have pressed q then quit
    if strcmp(KbName(keyCode>0), 'q')
        Quit=1;
        % Increase the visual angle
    elseif strcmp(KbName(keyCode>0), 'UpArrow')
        vis_angle = vis_angle + 1;
        % Decrease the visual angle
    elseif strcmp(KbName(keyCode>0), 'DownArrow')
        vis_angle = vis_angle - 1;
        % Switch between the test and the checkerboard image
    elseif strcmp(KbName(keyCode>0), 's')
        if all(img(1, 1, 1) == Checkerboard_img(1, 1, 1))
            img = test_display_img;
        else
            img = Checkerboard_img;
        end
        pause(0.1); % Wait so that it doesn't flick back
    end
    
    % Bottom out this number
    if vis_angle < 1
        vis_angle = 1;
    end
    
end

%Record whether this was quit preemptively
Screen('TextSize',Window.onScreen, 12);
Data.Quit=Quit;
Data.Timing.TestEnd=GetSecs;
Data.Timing.TR = [];

%Record the time at which the next experiment can start
Data.Timing.DecayLapse=Data.Timing.TestEnd+Conditions.Parameters.DecayTime;

%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end

