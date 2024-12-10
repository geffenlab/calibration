%% instructions
% materials:
% Bruel & Kjaer microphone + amplifier + power source
% Bruel & Kjaer tone generator

% make sure the tone generator has fresh batteries
% and make sure the mic + tone generator are in a quiet location


close('all')
close all

%% parameters
fs = 192e3;             % Playback and recording sampling frequency
rPa = 20e-6;            % Refers to assumed pressure (recorded?) in silence (reference point for 0 dB SPL)
vpPa = .316;            % Volts/Pascal conversion to get dB (microphone should use the same)
dur = 10;               % recording suration (s)
toneLevel = 94;         % Level of calibration tone (dB SPL) if playing from tone generator normally
% toneLevel = 114;        % Level of calibration tone (dB SPL) if holding "loud" button on the tone generator
recordingDevice = 'Record 01+02 (2- Lynx E44)';     % name of recording input device

%% set up recording device
InitializePsychSound;

devList = PsychPortAudio('GetDevices');
windowsDSIdx = find(cell2mat(cellfun(@(X)~isempty(strfind(X,'MME')),{devList(:).HostAudioAPIName},'UniformOutput',false))); %#ok<STREMP>
windowsDSIdx2 = find(cell2mat(cellfun(@(X)~isempty(strfind(X,'WASAPI')),{devList(:).HostAudioAPIName},'UniformOutput',false))); %#ok<STREMP>

recorderIdx = find(cell2mat(cellfun(@(X)strcmp(X,recordingDevice),{devList(:).DeviceName},'UniformOutput',false)));

recorderIdx = intersect(recorderIdx,windowsDSIdx);

ph.recorder = PsychPortAudio('Open',devList(recorderIdx).DeviceIndex,2,3,fs,1);


%% record  toneLevel dB SPL tone from tone generator

PsychPortAudio('GetAudioData',ph.recorder,dur,dur);

fprintf(['First: record calibrated %i dB tone.\n' ...
    'Place the mic in the tone generator and turn it on.\n' ...
    'Recording will start when you press any key.\n\n'],toneLevel);
pause;

t.rec  = PsychPortAudio('Start',ph.recorder,1);

tic; WaitSecs(dur); toc
[recCalibrationTone,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);


%% record silence

PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('GetAudioData',ph.recorder,dur,dur);

fprintf(['Next: record baseline noise.\n' ...
    'Leave the mic in the tone generator and turn it off.\n' ...
    'Recording will start when you press any key.\n\n']);
pause;

t.rec  = PsychPortAudio('Start',ph.recorder,1);

tic; WaitSecs(dur); toc
[recSilence,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);


%% calculate inGain necessary for input to equal toneLevel dB
meanSquare = @(x) mean((x-mean(x)).^2);

inputRMS = sqrt(meanSquare(recCalibrationTone/(rPa*vpPa))-meanSquare(recSilence/(rPa*vpPa)));
inGain = (10^(toneLevel/20))/inputRMS;

ax1 = subplot(1,2,1);
plot((1:length(recCalibrationTone))/fs,recCalibrationTone);
xlabel('Time (s)');
ylabel('Raw input');
title('Calibration tone');

ax2 = subplot(1,2,2);
plot((1:length(recSilence))/fs,recSilence);
xlabel('Time (s)');
ylabel('Raw input');
title('Noise');

linkaxes([ax1 ax2],'xy');


fprintf('Calculated gain in = %f\n',inGain);



%% clean up

close('all')
close all
