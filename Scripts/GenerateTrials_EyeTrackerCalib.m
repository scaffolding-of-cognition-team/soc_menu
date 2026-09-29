%% Generate Trial sequence and conditions for narrowing/localizer experiments

%Generate the appropriate trial sequence with randomization for a number of
%blocks in the EyeTrackerCalib experiment

%C Ellis 3/5/16

function TrialStructure=GenerateTrials_EyeTrackerCalib(varargin)

%If no inputs then just run
if nargin > 0
    PreGeneratedTrials = varargin{1}; %Specify that the first input refers to Pregenerated trials
    Window = varargin{4}; %Get the window for the experiment

end

%Set up the parameters of the experiment

Parameters.AddTaskRelevant=1; %Do you want to add task relevant features

Parameters.NumberofPoints=9; %How many stimuli will you present? Must be a square

Parameters.Repetitions=1; %How many times will you present each point?

Parameters.PointBoundary.Rect = Window.DisplayRect; % What is the rectangle of the point boundary in pixels

Parameters.PointBoundary.Square=20; %How many visual degrees is taken up by the box to be produced

Parameters.Boundary_shape = 'Rect'; % If this is 'Square' then it will use 'PointBoundary.Square' to make a square, otherwise it will use 'PointBoundary.Rect' to make a rectangle

Parameters.BlockNames={'Lines', 'Dots', 'Circles'}; %Calibration

Parameters.BlockNum=length(Parameters.BlockNames);

Parameters.DecayTime=0;

Parameters.RespondtoAdvance=1; %Is it necessary to respond in order to advance?

%Where can the fireworks appear
Counter=1;
if strcmp(Parameters.Boundary_shape, 'Square')
    DistSeq=(0:(Parameters.PointBoundarySize/(sqrt(Parameters.NumberofPoints)-1)):Parameters.PointBoundarySize) + (0-(Parameters.PointBoundarySize/2)); %What are the increments of this box
end
for xPointCounter=1: sqrt(Parameters.NumberofPoints)
    
    for yPointCounter=1: sqrt(Parameters.NumberofPoints)
        
        if strcmp(Parameters.Boundary_shape, 'Square')
            Stimuli.Origins(Counter,1) = DistSeq(xPointCounter); %What is the x coord
            Stimuli.Origins(Counter,2) = DistSeq(yPointCounter); %What is the y coord
        else
            % What are the dims
            width = Parameters.PointBoundary.Rect(3) - Parameters.PointBoundary.Rect(1);
            height = Parameters.PointBoundary.Rect(4) - Parameters.PointBoundary.Rect(2);

            % What proportion is this point
            xprop = xPointCounter / sqrt(Parameters.NumberofPoints);
            yprop = yPointCounter / sqrt(Parameters.NumberofPoints);
            
            % What is the position in pixels of this dot 
            x_pixel = (width * xprop) - (width / 2);
            y_pixel = (height * yprop) - (height / 2);
            
            % Convert to visual degrees (you will then convert back in the
            % code)
            Stimuli.Origins(Counter,1) = x_pixel / Window.ppd; %What is the x coord
            Stimuli.Origins(Counter,2) = y_pixel / Window.ppd; %What is the y coord

        end
        %Add a label to state what experiment is relevant for this location
        Stimuli.Origins_Experiments{Counter}='Experiment_EyeTrackerCalib'; 
        
        Counter=Counter+1;
        
    end
end

%Append these task relevant origins
%Numbers calibrated based on the scanner values
if Parameters.AddTaskRelevant==1
    
    %Iterate through the movies and pull out the locations, if relevant
    ExperimentsRun=fieldnames(PreGeneratedTrials);
    for ExperimentCounter=1:length(ExperimentsRun)
        
        % Try to do this but don't crash if this isn't available
        try
            % Store the names of the stimuli
            Experiment_Stimuli=PreGeneratedTrials.(ExperimentsRun{ExperimentCounter}).Stimuli;
            
            %If there were critical locations for this experiment then add them
            %to the list
            if isfield(Experiment_Stimuli, 'EyeTrackerCalib_Locations')==1
                
                Coords=Experiment_Stimuli.EyeTrackerCalib_Locations; %Output the coordinates
                
                Stimuli.Origins(end+1:end+size(Coords,1),:)=Coords; %Store these coordinates
                
                %Add a label to state the relevance of this location
                for Counter=1:size(Coords,1)
                    Stimuli.Origins_Experiments{end+1}=ExperimentsRun{ExperimentCounter};
                end
                
                %Report the extra locations
                warning(sprintf('%s has %d critical locations, adding to the list\n\n', ExperimentsRun{ExperimentCounter}, size(Coords,1)));
            end
            
        catch
            %Report the error
            warning(sprintf('%s does not have a .Stimuli substruct\n\n', ExperimentsRun{ExperimentCounter}));
        end
    end
    
end


Stimuli.Origins=repmat(Stimuli.Origins, Parameters.Repetitions, 1);

Stimuli.SelectedStimuli_Names='Fireworks';

%% Store the outputs

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
