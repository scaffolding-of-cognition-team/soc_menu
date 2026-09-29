% Generate videos that act as attention getters for the PlayAV task.
% These can be shown as part of PlayAV to reorient the infant to the screen by playing sounds, although they stay in the center.
% The stimuli used for generating this are based on LWL, as is the movement of the stimuli
% The script uses Menu's tools for opening the screen and also records the movies.

function generate_attention_getter_PlayAV(seed)

if nargin < 1
    seed = 1; % Default seed value if not provided
end

% Set up the screen
[window, windowRect] = PsychImaging('OpenWindow', 0, [0 0 0]);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

flipTime = Screen('GetFlipInterval', window); % Get the flip interval for timing

% Define the parameters for the attention getter

imageSize = 600; % Size of the image in pixels
AG.epoch_time = 1; % How long does each epoch of the Attention Getter last for?
AG.rotations = 1; % How many rotations should the image do?
AG.orbit_radius = 150; % How many visual degrees should you orbit from?
AG.scaling_factor = 2; % How much should the image grow/shrink?
AG.epoch_slope = 12; % How steep should the sigmoid be? 12 means the angles are right
AG.ISI = 0.2; % How long should the inter-stimulus interval be between attention getters?
reps_per_video = 10; % How many AGs will you try per video

% List out all the permutations
AG_path = '../../Stimuli/Simsom_LWL/AG_stimuli/';
AG.images = {'cupcake','earth','flower','heart','orb','pinwheel','ring','rocket','star','unicorn'};
AG.sounds = {'xylophone','bell','cuckoo','giggle','jump2','meow','powerup','squeak','whistle','whistle2'};
AG.motions = {'orbit', 'rotate', 'scale'};
AG.event_sequence = [1, 2, 2, 1]; % Event sequence where 1 is sound, 2 is an action, and 3 is movement to center

% Create a video writer object
% videoWriter = VideoWriter(sprintf('../Stimuli/AttentionGrabberVideos/AG_%02d.avi', seed));

% Get this seed and get as many permutations as required
rng(seed);

% Randomise the order of AG images and sounds then you will loop through them
AG.images = AG.images(randperm(length(AG.images)));
AG.sounds = AG.sounds(randperm(length(AG.sounds)));

% Duplicate motions and then shuffle
AG.motions = repmat(AG.motions, 1, ceil(reps_per_video / length(AG.motions)));
AG.motions = AG.motions(randperm(length(AG.motions)));

% 1. Initialize PsychPortAudio
InitializePsychSound(1);

% 2. Open device for recording (mode=2), 44.1kHz, 1-2 channels
pahandle = PsychPortAudio('Open', []);
s = PsychPortAudio('GetStatus', pahandle);
freq = s.SampleRate;

% 3. Preallocate internal buffer (e.g., 10 seconds)
PsychPortAudio('GetAudioData', pahandle);

% 4. Start recording
PsychPortAudio('Start', pahandle, 0, 0, 1);

for i = 1:reps_per_video

    % Randomly select an image, sound, and motion
    image = AG.images{i};
    sound = AG.sounds{i};
    motion = AG.motions{i};

    % Define the rectangle for the image
    RectAG = [xCenter-(imageSize / 2),yCenter-(imageSize / 2),xCenter+(imageSize / 2),yCenter+(imageSize / 2)];
    current_angle = 0; % Start with the image at 0 degrees

    % Specify the sound for the attention getter
    [AG.wave, AG.fs] = audioread([AG_path, sound, '.mp3']);

    % Load in the image
    [iImageAG, ~, Alphachannel]=imread([AG_path, image, '.png']);

    % Add the alpha channel
    iImageAG(:,:,4)=Alphachannel;

    % Set up the texture
    ImageTexAG=Screen('MakeTexture', window, iImageAG);
    Screen('FillRect', window, [50 50 50]);
    Screen('DrawTexture', window, ImageTexAG, [], RectAG, current_angle); %Draw the image on the left
    Screen('Flip',window);

    % Initiate event sequence
    for event = AG.event_sequence

        % Initialize
        epoch_onset = GetSecs;

        % Switch the case depending on the action
        switch event
            case 1 % Sound plays

                % Load in the speaker object
                speaker_obj=audioplayer(AG.wave, AG.fs, 16); % Set up the audio object with 8 bit
                play(speaker_obj); % This ensures that the audio finishes
                while epoch_onset + AG.epoch_time - flipTime > GetSecs
                    % Wait
                end
            case 2 % initiate the action. There are different types of motions

                while epoch_onset + AG.epoch_time - flipTime > GetSecs

                    % How long has the rotation being happening for
                    AG.motion_duration = GetSecs - epoch_onset;

                    % Where is the current x location (could change with movement to the center)
                    current_center_x = ((RectAG(3) + RectAG(1)) / 2);

                    % Switch the case depending on the motion
                    Screen('FillRect', window, [50 50 50]); % Put the background in
                    switch motion
                        
                        case 'orbit'
                            % Animate an orbit of the image around the center of the image
                            current_angle = (AG.rotations * 360) / (1 + exp(-AG.epoch_slope * (AG.motion_duration - (AG.epoch_time / 2)))); % This is the angle on the orbit of the circle

                            % How far from the center of the image should the orbit be?
                            orbit_radius = AG.orbit_radius;

                            % 0 degrees is the resting position, so you must compute the new center of the orbit relative to that
                            orbit_center = current_center_x - orbit_radius; % This is the center of the image

                            % Compute the center of the shape at this moment for this angle
                            current_center_x = orbit_center + orbit_radius * cosd(current_angle);
                            current_center_y = yCenter + orbit_radius * sind(current_angle);

                            current_RectAG = [current_center_x-(imageSize / 2),current_center_y-(imageSize / 2),current_center_x+(imageSize / 2),current_center_y+(imageSize / 2)];

                            % Draw the attention getter image
                            Screen('DrawTexture', window, ImageTexAG, [], current_RectAG);

                        case 'rotate'
                            % Animate a rotation of the image. Start by first specifying the angle steps the image will be in. Make it accelerate, reach its max speed, and then decelerate in its rotation. Thus the angle values will make a sigmoid
                            % The sigmoid will be defined as:
                            % f(x) = $ROTATIONAL_DEGREES / (1 + exp(-$SLOPE*(x-$PERIOD/2)))
                            current_angle = (AG.rotations * 360) / (1 + exp(-AG.epoch_slope * (AG.motion_duration - (AG.epoch_time / 2))));

                            % Draw the attention getter image
                            Screen('DrawTexture', window, ImageTexAG, [], RectAG, current_angle); %Draw the image on the left

                        case 'scale'
                            % Animate the scaling, going from the current size to double the size and then back by modeling a sinusoid
                            time_proportion = AG.motion_duration / AG.epoch_time;
                            current_scaling = sin(time_proportion * pi * 2);

                            % Negative values should range from 1-1/K, positive values should range from 1-K where K is the scaling factor
                            if current_scaling < 0
                                current_scaling = 1 - (abs(current_scaling) / AG.scaling_factor);
                            else
                                current_scaling = (current_scaling * (AG.scaling_factor - 1)) + 1;
                            end

                            current_RectAG = [current_center_x-(imageSize * current_scaling / 2),yCenter-(imageSize * current_scaling / 2),current_center_x+(imageSize * current_scaling / 2),yCenter+(imageSize * current_scaling / 2)];

                            % Draw the attention getter image
                            Screen('DrawTexture', window, ImageTexAG, [], current_RectAG); %Draw the image on the left
                    end

                    Screen('Flip',window);

                end

        end
    end

    % Show a blank screen for a moment before end of the next trial
    Screen('FillRect', window, [50 50 50]);
    Screen('Flip',window);
    WaitSecs(AG.ISI);
end

% 5. Fetch recorded data
audiodata = PsychPortAudio('GetAudioData', pahandle);

% 6. Stop and Close
PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);

audiowrite('~/Desktop/AG_demo.mp4', audiodata, freq)

% Close all
sca