% The experiment investigates the neural responses to visual stimuli presented either in the fovea (central vision) or
% in the periphery (peripheral vision). Stimuli include words, and scenes,

% Define the function to generate trials for the eccentricity experiment
function TrialStructure = GenerateTrials_Whole_Eccentricity(varargin)

% Define parameters for the experiment
Parameters.radius_deg = 10;               % Peripheral ring radius of images in degrees
Parameters.image_width_deg = 4;           % Image width in degrees
Parameters.stim_duration = 0.7;           % Each image presented for 700 ms and 300 ms off
Parameters.stim_duration_off = 0.3;       % 300 ms off
Parameters.DecayLapse = 6;               % Set the duration of decay lapse in seconds 
Parameters.ITI_on = 6;                    % Inter-trial interval (6 seconds)
Parameters.block_duration = 14;           % Each block represents 1 of the 6 epoch types
Parameters.num_trials_per_epoch = 14; 
Parameters.StimulusDirectory = '../Stimuli/eccentricity/';

Parameters.BlockNames = {'Fixation_Static'};  

Parameters.BlockNum = length(Parameters.BlockNames); 

%%%%%%%% Load stimuli paths %%%%%%%%

% Scenes
scenes_intact_Dir = fullfile(Parameters.StimulusDirectory, 'scenes_intact');
scenes_intact_Files = dir(fullfile(scenes_intact_Dir, '*.jpg'));

% Phase-scrambled scenes
phase_scrambled_scenesDir = fullfile(Parameters.StimulusDirectory, 'phase_scrambled');
phase_scrambled_sceneFiles = dir(fullfile(phase_scrambled_scenesDir, '*.jpg'));  

% Store the directories and file lists in the TrialStructure
TrialStructure.scenes_intact_Dir = scenes_intact_Dir;
TrialStructure.scenes_intact_Files = scenes_intact_Files;
TrialStructure.phase_scrambled_scenesDir = phase_scrambled_scenesDir;
TrialStructure.phase_scrambled_sceneFiles = phase_scrambled_sceneFiles;

TrialStructure.Parameters = Parameters;

end