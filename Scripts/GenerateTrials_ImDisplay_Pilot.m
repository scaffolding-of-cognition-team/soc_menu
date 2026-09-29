%% Generate Trial sequence and conditions for showing an image

%Simply show an image

%C Ellis 6/25/18

function TrialStructure=GenerateTrials_ImDisplay_Pilot(varargin)

%Set up the parameters of the experiment
Parameters.BlockNames={'Image'}; %Calibration

Parameters.BlockNum=length(Parameters.BlockNames);

Parameters.DecayTime=0;

Stimuli.SelectedStimuli_Names='../Stimuli/test_display.jpeg';

%% Store the outputs

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
