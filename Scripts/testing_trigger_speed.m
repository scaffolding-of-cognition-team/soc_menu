%% Script to listen to triggers and report the delay between them

function testing_trigger_speed(mode)

%device_names.ScannerNum = 'Apple Internal Keyboard / Trackpad';
device_names.ScannerNum = '932'; %name of device you want to poll

Window = struct;

% Find the index numbers of all the devices
device_fields=fieldnames(device_names);
[index, devName] = GetKeyboardIndices;
for device_counter = 1:length(index)
    for name_counter = 1:length(device_fields)
        device_field=device_fields{name_counter};    
        
        if isnumeric(device_names.(device_field))
            Window.(device_field)= device_names.(device_field);
        else
            if ~cellfun(@isempty, strfind(devName(device_counter), device_names.(device_field))) % Make it so it will not overwrite the first keyboard if there are multiple attached
                Window.(device_field)= index(device_counter);
            end
        end
    end
end


% Set up the KbQueue function, establishing two queues, one for the
% scanner and response box, one for the keyboard
if isfield(Window, 'ScannerNum')
    KbQueueCreate(Window.ScannerNum);
    KbQueueStart(Window.ScannerNum);
end


KbName('UnifyKeyNames');

% Set up variables
KeyNumber = KbName('5%');
DEVICE=Window.ScannerNum;

fprintf('Waiting for triggers, start scanner when you are ready\n\n')
ListenChar(2);

% Mode == 1 Fastest possible loops
last_trigger=GetSecs;
end_time = last_trigger + 30;
TR = 1; 
    
while end_time > GetSecs
    if mode == 1
        [keydown,trigger_onset,~,second_trigger_onset] = KbQueueCheck(DEVICE);
        trigger_onset = trigger_onset(KeyNumber);
        second_trigger_onset = second_trigger_onset(KeyNumber);
        
    else
        if mode == 2
            triggers = Utils_checkTrigger(last_trigger + TR, DEVICE);
        elseif mode == 3
            triggers = Utils_checkTrigger(0, DEVICE);
        end

        trigger_onset = triggers(1);
        if length(triggers) == 2 
            second_trigger_onset = triggers(2);
        else
            second_trigger_onset = 0;
        end
        
        if trigger_onset > 0 
            keydown = 1;
        else
            keydown = 0;
        end

    end

    if keydown
        % Two triggers came in, so check both
        if second_trigger_onset - trigger_onset>0
            fprintf('%0.4f s\n', trigger_onset - last_trigger);

            fprintf('%0.4f s\n', second_trigger_onset - trigger_onset);

            last_trigger = second_trigger_onset;
        else
            fprintf('%0.4f s\n', trigger_onset - last_trigger);
            last_trigger = trigger_onset;
        end
    end

end

ListenChar(1);
