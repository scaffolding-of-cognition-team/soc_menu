%% Monitor for triggers and report their timestamps to a CSV file in the Data folder. This can be useful for monitoring what triggers to expect from a sequence

% Specify the output file, with the date and time in the name
out_file = sprintf('../Data/trigger_log_%s.csv', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));

% Open the file for writing
fid = fopen(out_file, 'w');


device_names.ScannerNum = 'Apple Internal Keyboard / Trackpad';
% device_names.ScannerNum = '932'; %name of device you want to poll

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

% Set up variables
KeyNumber = KbName('5%');
DEVICE=Window.ScannerNum;

fprintf('Waiting for triggers, start scanner when you are ready\n\n')
ListenChar(2);

start_time = GetSecs;
fprintf(fid, 'Start time: %0.1f\n', start_time);
trigger_counter = 1;
while 1

    % Get the key press
    TRRecording=Utils_checkTrigger(0, Window.ScannerNum);

    % Store the TR time in the csv and print it out
    if any(TRRecording > 0)
        for i = 1:length(TRRecording)
            fprintf(fid, '%d\t%f\n', trigger_counter, TRRecording(i) - start_time);
            fprintf('%d\t%f\n', trigger_counter, TRRecording(i) - start_time); % Print it out too
        end
x    end

    % Check to see in any keyboard if a q was pressed
    [pressed, firstPress]=KbQueueCheck();
    if pressed
        if firstPress(KbName('q'))
            break
        end
    end
end

fprintf(fid, 'End time: %0.1f\n', GetSecs);
fclose(fid);
