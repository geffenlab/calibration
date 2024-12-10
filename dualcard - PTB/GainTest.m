
playbackDevice = 'Speakers (2- Lynx E44)';
recordingDevice = 'Record 01+02 (2- Lynx E44)'; % for booths 1-2, 3-4, recording device is (2- Lynx E44)
% recordingDevice = 'Record 01+02 (Lynx E44)'; % for booths 5-6 recording device is (Lynx E44)


targetVol = 70;         % Desired volume of filtered output
lowerFreq = 3e3;        % Lower freq cutoff for filter
upperFreq = 70e3;       % Upper freq cutoff for filter (dB of filtered audio between low/upp should be ~equal)
fs = 192e3;             % Playback and recording sampling frequency
rPa=20e-6;              % Refers to assumed pressure (recorded?) in silence
vpPa=.316;              % Volts/Pascal conversion to get dB
inGain = 6;             % Mic multiplies input by 6 (?)
outGain = 11;           % The speakers multiply output by 11, so need to scale beforehand

testSoundDuration = 10;

InitializePsychSound;


devList = PsychPortAudio('GetDevices');
windowsDSIdx = find(cell2mat(cellfun(@(X)~isempty(strfind(X,'MME')),{devList(:).HostAudioAPIName},'UniformOutput',false))); %#ok<STREMP>
windowsDSIdx2 = find(cell2mat(cellfun(@(X)~isempty(strfind(X,'WASAPI')),{devList(:).HostAudioAPIName},'UniformOutput',false))); %#ok<STREMP>

playbackIdx = find(cell2mat(cellfun(@(X)strcmp(X,playbackDevice),{devList(:).DeviceName},'UniformOutput',false)));
recorderIdx = find(cell2mat(cellfun(@(X)strcmp(X,recordingDevice),{devList(:).DeviceName},'UniformOutput',false)));

playbackIdx = intersect(playbackIdx,windowsDSIdx);
recorderIdx = intersect(recorderIdx,windowsDSIdx);

% Open audio channels. Set appropriate input params so that one is playback
% and the other is recording. The third parameter determins mode (1 = play,
% 2 = record). See PTB docs for more information.
%ph.player   = PsychPortAudio('Open',devList(playbackIdx).DeviceIndex,1,3,fs,1);
ph.recorder = PsychPortAudio('Open',devList(recorderIdx).DeviceIndex,2,3,fs,1);


toneDuration = 2;
recorderBuffer = 2;

% 
% %PsychPortAudio('GetAudioData',ph.recorder);
% PsychPortAudio('GetAudioData',ph.recorder, toneDuration + recorderBuffer,toneDuration + recorderBuffer);
% 
% % Record and play
% t.rec  = PsychPortAudio('Start',ph.recorder,1);
% 
% 
% tic; pause(toneDuration + recorderBuffer); toc
% [calibrated94dBtone,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
% PsychPortAudio('Stop',ph.recorder);
% 
% %

%PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('GetAudioData',ph.recorder, toneDuration + recorderBuffer,toneDuration + recorderBuffer);
t.rec  = PsychPortAudio('Start',ph.recorder,1);
tic; pause(toneDuration + recorderBuffer); toc
[recSilence,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);



plot(recSilence)



%%
% 
% 
if false
    
    
    close('all')
    close all
    clear


end
