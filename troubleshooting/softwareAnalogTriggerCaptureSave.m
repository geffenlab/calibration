function softwareAnalogTriggerCaptureSave
%softwareAnalogTriggerCapture DAQ data capture using software-analog triggering
%   softwareAnalogTriggerCapture launches a user interface for live DAQ data
%   visualization and interactive data capture based on a software analog
%   trigger condition.

% setup non-ASIO LYNX card
device = '2- Lynx E44';
d = daq.getDevices;
description = sprintf('DirectSound Record 01+02 (%s)',device);
ind = find(strcmp({d.Description},description));
dev = d(ind);
s = daq.createSession('directsound');
ch = addAudioInputChannel(s,dev.ID,1);

% Set acquisition rate, in scans/second
s.Rate = 192e3;

% Specify the desired parameters for data capture and live plotting.
% The data capture parameters are grouped in a structure data type,
% as this makes it simpler to pass them as a function argument.

% Specify triggered capture timespan, in seconds
capture.TimeSpan = 1;

% Specify continuous data plot timespan, in seconds
capture.plotTimeSpan = 1.05;

% Determine the timespan corresponding to the block of samples supplied
% to the DataAvailable event callback function.
callbackTimeSpan = double(s.NotifyWhenDataAvailableExceeds)/s.Rate;
% Determine required buffer timespan, seconds
capture.bufferTimeSpan = max([capture.plotTimeSpan, capture.TimeSpan * 3, callbackTimeSpan * 3]);
% Determine data buffer size
capture.bufferSize =  round(capture.bufferTimeSpan * s.Rate);

% Display graphical user interface
hGui = createDataCaptureUI(s);

% Add a listener for DataAvailable events and specify the callback function
% The specified data capture parameters and the handles to the UI graphics
% elements are passed as additional arguments to the callback function.
dataListener = addlistener(s, 'DataAvailable', @(src,event) dataCapture(src, event, capture, hGui));

% Add a listener for acquisition error events which might occur during background acquisition
errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));

% Start continuous background data acquisition
s.IsContinuous = true;
startBackground(s);

% Wait until session s is stopped from the UI
while s.IsRunning
    pause(0.5);
end

delete(dataListener);
delete(errorListener);
delete(s);
end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local Functions
function dataCapture(src, event, c, hGui)
%dataCapture Process DAQ acquired data when called by DataAvailable event.
%  dataCapture (SRC, EVENT, C, HGUI) processes latest acquired data (EVENT.DATA)
%  and timestamps (EVENT.TIMESTAMPS) from session (SRC), and, based on specified
%  capture parameters (C structure) and trigger configuration parameters from
%  the user interface elements (HGUI handles structure), updates UI plots
%  and captures data.
%
%   c.TimeSpan        = triggered capture timespan (seconds)
%   c.bufferTimeSpan  = required data buffer timespan (seconds)
%   c.bufferSize      = required data buffer size (number of scans)
%   c.plotTimeSpan    = continuous acquired data timespan (seconds)
%

% The incoming data (event.Data and event.TimeStamps) is stored in a
% persistent buffer (dataBuffer), which is sized to allow triggered data
% capture.

% Since multiple calls to dataCapture will be needed for a triggered
% capture, a trigger condition flag (trigActive) and a corresponding
% data timestamp (trigMoment) are used as persistent variables.
% Persistent variables retain their values between calls to the function.

persistent dataBuffer trigActive trigMoment cnt saveData

% If dataCapture is running for the first time, initialize persistent vars
if event.TimeStamps(1)==0
    dataBuffer = [];          % data buffer
    trigActive = false;       % trigger condition flag
    trigMoment = [];          % data timestamp when trigger condition met
    cnt = 0;
    saveData = [];
    prevData = [];            % last data point from previous callback execution
else
    prevData = dataBuffer(end, :);
end

% Store continuous acquistion data in persistent FIFO buffer dataBuffer
latestData = [event.TimeStamps, event.Data];
dataBuffer = [dataBuffer; latestData];
numSamplesToDiscard = size(dataBuffer,1) - c.bufferSize;
if (numSamplesToDiscard > 0)
    dataBuffer(1:numSamplesToDiscard, :) = [];
end


% Update live data plot
% Plot latest plotTimeSpan seconds of data in dataBuffer
samplesToPlot = min([round(c.plotTimeSpan * src.Rate), size(dataBuffer,1)]);
firstPoint = size(dataBuffer, 1) - samplesToPlot + 1;
% Update x-axis limits
xlim(hGui.Axes1, [dataBuffer(firstPoint,1), dataBuffer(end,1)]);
% Live plot has one line for each acquisition channel
for ii = 1:numel(hGui.LivePlot)
    set(hGui.LivePlot(ii), 'XData', dataBuffer(firstPoint:end, 1), ...
                           'YData', dataBuffer(firstPoint:end, 1+ii))
end


% If capture is requested, analyze latest acquired data until a trigger
% condition is met. After enough data is acquired for a complete capture,
% as specified by the capture timespan, extract the capture data from the
% data buffer and save it to a base workspace variable.

% Get capture toggle button value (1 or 0) from UI
captureRequested = get(hGui.CaptureButton, 'value');

if captureRequested && (~trigActive)
    % State: "Looking for trigger event"

    % Update UI status
    set(hGui.StatusText, 'String', 'Waiting for trigger');

    % Get the trigger configuration parameters from UI text inputs and
    %   place them in a structure.
    % For simplicity, validation of user input is not addressed in this example.
    trigConfig.Channel = sscanf(get(hGui.TrigChannel, 'string'), '%u');
    trigConfig.Level = sscanf(get(hGui.TrigLevel, 'string'), '%f');
    trigConfig.Slope = sscanf(get(hGui.TrigSlope, 'string'), '%f');

    % Determine whether trigger condition is met in the latest acquired data
    % A custom trigger condition is defined in trigDetect user function
    [trigActive, trigMoment] = trigDetect(prevData, latestData, trigConfig);


elseif captureRequested && trigActive && ((dataBuffer(end,1)-trigMoment) > c.TimeSpan)
    % State: "Acquired enough data for a complete capture"
    % If triggered and if there is enough data in dataBuffer for triggered
    % capture, then captureData can be obtained from dataBuffer.
    cnt = cnt + 1;

    % Find index of sample in dataBuffer with timestamp value trigMoment
    trigSampleIndex = find(dataBuffer(:,1) == trigMoment, 1, 'first');
    % Find index of sample in dataBuffer to complete the capture
    lastSampleIndex = round(trigSampleIndex + c.TimeSpan * src.Rate());
    captureData = dataBuffer(trigSampleIndex:lastSampleIndex, :);
    saveData(cnt,:) = captureData(:,2);

    % Reset trigger flag, to allow for a new triggered data capture
    trigActive = false;

    % Update captured data plot (one line for each acquisition channel)
    for ii = 1:numel(hGui.CapturePlot)
        set(hGui.CapturePlot(ii), 'XData', captureData(:, 1), ...
                                  'YData', captureData(:, 1+ii))
    end

    % Update UI to show that capture has been completed
    set(hGui.CaptureButton, 'Value', 0);
    set(hGui.StatusText, 'String', '');

    % Save captured data to a base workspace variable
    % For simplicity, validation of user input and checking whether a variable
    % with the same name already exists are not addressed in this example.
    % Get the variable name from UI text input
    varName = get(hGui.VarName, 'String');
    % Use assignin function to save the captured data in a base workspace variable
    %assignin('base', varName, captureData);
    
    % save to file "varName" instead
    save(varName,'saveData');

elseif captureRequested && trigActive && ((dataBuffer(end,1)-trigMoment) < c.TimeSpan)
    % State: "Capturing data"
    % Not enough acquired data to cover capture timespan during this callback execution
    set(hGui.StatusText, 'String', 'Triggered');

elseif ~captureRequested
    % State: "Capture not requested"
    % Capture toggle button is not pressed, set trigger flag and update UI
    trigActive = false;
    set(hGui.StatusText, 'String', '');
end

drawnow;

end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hGui = createDataCaptureUI(s)
%CREATEDATACAPTUREUI Create a graphical user interface for data capture.
%   HGUI = CREATEDATACAPTUREUI(S) returns a structure of graphics
%   components handles (HGUI) and creates a graphical user interface, by
%   programmatically creating a figure and adding required graphics
%   components for visualization of data acquired from a DAQ session (S).

% Create a figure and configure a callback function (executes on window close)
hGui.Fig = figure('Name','Software-analog triggered data capture', ...
    'NumberTitle', 'off', 'Resize', 'off', 'Position', [100 100 750 650]);
set(hGui.Fig, 'DeleteFcn', {@endDAQ, s});
uiBackgroundColor = get(hGui.Fig, 'Color');

% Create the continuous data plot axes with legend
% (one line per acquisition channel)
hGui.Axes1 = axes;
hGui.LivePlot = plot(0, zeros(1, numel(s.Channels)));
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Continuous data');
legend(get(s.Channels, 'ID'), 'Location', 'northwestoutside')
set(hGui.Axes1, 'Units', 'Pixels', 'Position',  [207 391 488 196]);

% Create the captured data plot axes (one line per acquisition channel)
hGui.Axes2 = axes('Units', 'Pixels', 'Position', [207 99 488 196]);
hGui.CapturePlot = plot(NaN, NaN(1, numel(s.Channels)));
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Captured data');

% Create a stop acquisition button and configure a callback function
hGui.DAQButton = uicontrol('style', 'pushbutton', 'string', 'Stop DAQ',...
    'units', 'pixels', 'position', [65 394 81 38]);
set(hGui.DAQButton, 'callback', {@endDAQ, s});

% Create a data capture button and configure a callback function
hGui.CaptureButton = uicontrol('style', 'togglebutton', 'string', 'Capture',...
    'units', 'pixels', 'position', [65 99 81 38]);
set(hGui.CaptureButton, 'callback', {@startCapture, hGui});

% Create a status text field
hGui.StatusText = uicontrol('style', 'text', 'string', '',...
    'units', 'pixels', 'position', [67 28 225 24],...
    'HorizontalAlignment', 'left', 'BackgroundColor', uiBackgroundColor);

% Create an editable text field for the captured data variable name
hGui.VarName = uicontrol('style', 'edit', 'string', 'file.mat',...
    'units', 'pixels', 'position', [87 159 57 26]);
% Create an editable text field for the trigger channel
hGui.TrigChannel = uicontrol('style', 'edit', 'string', '1',...
    'units', 'pixels', 'position', [89 258 56 24]);
% Create an editable text field for the trigger signal level
hGui.TrigLevel = uicontrol('style', 'edit', 'string', '.001',...
    'units', 'pixels', 'position', [89 231 56 24]);
% Create an editable text field for the trigger signal slope
hGui.TrigSlope = uicontrol('style', 'edit', 'string', '200.0',...
    'units', 'pixels', 'position', [89 204 56 24]);
% Create text labels
hGui.txtTrigParam = uicontrol('Style', 'text', 'String', 'Trigger parameters', ...
    'Position', [39 290 114 18], 'BackgroundColor', uiBackgroundColor);
hGui.txtTrigChannel = uicontrol('Style', 'text', 'String', 'Channel', ...
    'Position', [37 261 43 15], 'HorizontalAlignment', 'right', ...
    'BackgroundColor', uiBackgroundColor);
hGui.txtTrigLevel = uicontrol('Style', 'text', 'String', 'Level (V)', ...
    'Position', [35 231 48 19], 'HorizontalAlignment', 'right', ...
    'BackgroundColor', uiBackgroundColor);
hGui.txtTrigSlope = uicontrol('Style', 'text', 'String', 'Slope (V/s)', ...
    'Position', [17 206 66 17], 'HorizontalAlignment', 'right', ...
    'BackgroundColor', uiBackgroundColor);
hGui.txtVarName = uicontrol('Style', 'text', 'String', 'File name', ...
    'Position', [35 152 44 34], 'BackgroundColor', uiBackgroundColor);

end

function startCapture(hObject, ~, hGui)
if get(hObject, 'value')
    % If button is pressed clear data capture plot
    for ii = 1:numel(hGui.CapturePlot)
        set(hGui.CapturePlot(ii), 'XData', NaN, 'YData', NaN);
    end
end
end

function endDAQ(~, ~, s)
if isvalid(s)
    if s.IsRunning
        stop(s);
    end
end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [trigDetected, trigMoment] = trigDetect(prevData, latestData, trigConfig)
%TRIGDETECT Detect if trigger condition is met in acquired data
%   [TRIGDETECTED, TRIGMOMENT] = TRIGDETECT(PREVDATA, LATESTDATA, TRIGCONFIG)
%   Returns a detection flag (TRIGDETECTED) and the corresponding timestamp
%   (TRIGMOMENT) of the first data point which meets the trigger condition
%   based on signal level and slope specified by the trigger parameters
%   structure (TRIGCONFIG).
%   The input data (LATESTDATA) is an N x M matrix corresponding to N acquired
%   data scans, with the timestamps as the first column, and channel data
%   as columns 2:M. The previous data point PREVDATA (1 x M vector of timestamp
%   and channel data) is used to determine the slope of the first data point.
%
%   trigConfig.Channel = index of trigger channel in session channels
%   trigConfig.Level   = signal trigger level (V)
%   trigConfig.Slope   = signal trigger slope (V/s)

% Condition for signal trigger level
trigCondition1 = latestData(:, 1+trigConfig.Channel) > trigConfig.Level;

data = [prevData; latestData];

% Calculate slope of signal data points
% Calculate time step from timestamps
dt = latestData(2,1)-latestData(1,1);
slope = diff(data(:, 1+trigConfig.Channel))/dt;

% Condition for signal trigger slope
trigCondition2 = slope > trigConfig.Slope;

% If first data block acquired, slope for first data point is not defined
if isempty(prevData)
    trigCondition2 = [false; trigCondition2];
end

% Combined trigger condition to be used
trigCondition = trigCondition1 & trigCondition2;

trigDetected = any(trigCondition);
trigMoment = [];
if trigDetected
    % Find time moment when trigger condition has been met
    trigTimeStamps = latestData(trigCondition, 1);
    trigMoment = trigTimeStamps(1);
end
end












