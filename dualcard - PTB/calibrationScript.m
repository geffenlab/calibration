%% calibrationScript
%
% This script runs the calibration for a dual sound card setup for the
% behavior booths. Using PTB, we can run this script from just once
% instance in Matlab.
%
% Specifically, this script will do the follwing:
% 1. Play white noise and create a filter using the recorded audio.
% 2. Play filtered white noise to verify that filter works.
% 3. Play filtered pure tones to verify that filter works.
%
% Since PTB will be used for most of the audio interfacing, here is a
% convenient link to the PTB audio documentation:
% http://docs.psychtoolbox.org/PsychPortAudio
%
% NOTE: There is some weird time discrepancy between Matlab/PTB/audio. The
% pause function seems to pause for the correct amount of time, but the
% audio plays for much longer...

clear; close all;
%% Parameter
%
% These parameters determine everything that the script does. Thus, these
% are the only variables that should ever need changing (bar discovery of a
% bug in the code D:).

% These are strings corresponding to the DeviceName field in the struct
% array output from the PsychPortAudio('GetDevices') subfunction. Pair
% 'Speakers Lynx ...' ('Speakers 2- Lynx ...') with 'Record 01 ... 2- Lynx'
% ('Record 01 ... Lynx').
playbackDevice = 'Speakers (Lynx E44)';
recordingDevice = 'Record 01+02 (2- Lynx E44)';

targetVol = 70;         % Desired volume of filtered output
lowerFreq = 3e3;        % Lower freq cutoff for filter
upperFreq = 70e3;       % Upper freq cutoff for filter (dB of filtered audio between low/upp should be ~equal)
fs = 192e3;             % Playback and recording sampling frequency
rPa=20e-6;              % Refers to assumed pressure (recorded?) in silence
vpPa=.316;              % Volts/Pascal conversion to get dB
inGain = 11;             % Mic multiplies input by 6 (?)
outGain = 11;           % The speakers multiply output by 11, so need to scale beforehand

testSoundDuration = 20; % How long to play the white noise for making the filter in seconds
isOctave = true;        % Boolean to tell if running from Octave. If true, rescales overlap in pwelch (stupid Octave/Matlab incompatibility)
boothNumber = 7;        % Which booth we are calibrating, used to generate filter name

%% Need to load signaling package if using Octave
if isOctave
    pkg load signal
end

%% Set up PTB audio
%
% Here, we initialize the PTB audio interface and load up the appropriate
% audio devices. Note that we will specifically only use the Windows
% DirectSound drivers.

InitializePsychSound;

% Find appropriate device indices. Matlab is going to recommend using
% 'contains' instead of 'emtpy(strfind())'. However, octave does not have
% the 'contains' function, so this warning here is suppressed.
devList = PsychPortAudio('GetDevices');
windowsDSIdx = find(cell2mat(cellfun(@(X)~isempty(strfind(X,'MME')),{devList(:).HostAudioAPIName},'UniformOutput',false))); %#ok<STREMP>
playbackIdx = find(cell2mat(cellfun(@(X)strcmp(X,playbackDevice),{devList(:).DeviceName},'UniformOutput',false)));
recorderIdx = find(cell2mat(cellfun(@(X)strcmp(X,recordingDevice),{devList(:).DeviceName},'UniformOutput',false)));

playbackIdx = intersect(playbackIdx,windowsDSIdx);
recorderIdx = intersect(recorderIdx,windowsDSIdx);

% Open audio channels. Set appropriate input params so that one is playback
% and the other is recording. The third parameter determins mode (1 = play,
% 2 = record). See PTB docs for more information.
ph.player   = PsychPortAudio('Open',devList(playbackIdx).DeviceIndex,1,3,fs,1);
ph.recorder = PsychPortAudio('Open',devList(recorderIdx).DeviceIndex,2,3,fs,1);

%% Step 1
%
% We will generate a white noise tone to play. Then, we will pre-allocate
% buffers to both the playback and recording devices. The recording device
% will have a slightly larger buffer than the playback device since we will
% start the recorder first. PTB gives us timestamps for almost everything
% so we can record slightly more and align the data later.

% Create a random white noise tone. PTB accepts matrices of sound data
% where each row corresponds to a channel. Also scale by the sound output
% gain.
whiteNoiseTone = randn(1,fs*testSoundDuration) / outGain;
PsychPortAudio('FillBuffer',ph.player,whiteNoiseTone);

% Pre-allocate buffer for recorder. This is done via the 'GetAudioData'
% subfunction. Refer to PTB docs for more details. Give the recorder an
% extra 2 seconds of buffer space over the player
recorderBuffer = 2;
PsychPortAudio('GetAudioData',ph.recorder,testSoundDuration + recorderBuffer,testSoundDuration + recorderBuffer);

% Start recording and playback
t.rec  = PsychPortAudio('Start',ph.recorder,1);
t.play = PsychPortAudio('Start',ph.player,1);

% Wait for duration. Then gather audio data from recorder and stop it.
% Otherwise it will continue to record and overwrite the data in its
% buffer!
tic; WaitSecs(testSoundDuration + recorderBuffer); toc
[recWhiteNoise,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);

%% Create filter
%
% Now that we have the recorded data sample, we will create a filter using
% it. We will take data from the recording start at the 1st second until
% the end - 2 seconds. This will clip some of the data, but ensure we are
% using only recorded white noise.
dataForFilter = recWhiteNoise(fs : length(recWhiteNoise) - 2*fs);

% Below is code copied from 'recordCalibrationStim' in the dual card
% folder. Not sure what it does exactly, but it makes the filter...
noiseAdj = dataForFilter(1,1000:end-1000) * inGain / rPa / vpPa;
overlapScale = isOctave * 1024 + ~isOctave * 1;
[P,f] = pwelch(noiseAdj,1024,120/overlapScale,[],fs,'onesided');
dB = 10*log10(P);
f1 = figure(1); clf; hold on
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);

% make a filter
FILT = makeFilter(P,f,fs,lowerFreq,upperFreq,targetVol);

%% Step 2
%
% We generate a new sample of white noise and filter it using the filter
% from above. We then record again and plot the filtered results.
whiteNoiseFilt = randn(1,fs*testSoundDuration) / outGain;
whiteNoiseFilt = conv(whiteNoiseFilt,FILT,'same');

% Now to refill the audio buffers. Not that we need to flush the recording
% buffer first by making another call to 'GetAudioData' before
% initializing.
PsychPortAudio('FillBuffer',ph.player,whiteNoiseFilt);
PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('GetAudioData',ph.recorder,testSoundDuration + recorderBuffer,testSoundDuration + recorderBuffer);

% Start recording and playback
t.rec  = PsychPortAudio('Start',ph.recorder,1);
t.play = PsychPortAudio('Start',ph.player,1);

% Wait for duration. Then gather audio data from recorder and stop it.
% Otherwise it will continue to record and overwrite the data in its
% buffer!
tic; WaitSecs(testSoundDuration + recorderBuffer); toc
[recFiltNoise,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);

% Plot resulting spectra. Similar to when computing the filter.
dataForFilter = recFiltNoise(fs : length(recFiltNoise) - 2*fs);
noiseAdj = dataForFilter(1,1000:end-1000) * inGain / rPa / vpPa;
[P,f] = pwelch(noiseAdj,1024,120/overlapScale,[],fs,'onesided');
dB = 10*log10(P);
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);

%% Step 3
%
% We generate a series of filtered pure tones to play and record. These
% tones will be within the frequency range of our filter (specified in the
% parameters at the top of the script).

toneFs = 3500:5000:65000;
toneDuration = 2;
recTones = cell(length(toneFs),1);
for ii = 1:length(toneFs)
    
    % Generate tone and print a status update to let us know what's going
    % on!
    f = toneFs(ii);
    fprintf('Playing tone %02d/%02d @ %dHz\n',ii,length(toneFs),f);
    tonef = tone(f,1,toneDuration,fs);
    tonef = envelopeKCW(tonef,5,fs) / outGain;
    tonef = conv(tonef,FILT,'same');
    
    % Buffer up playback and recording
    PsychPortAudio('FillBuffer',ph.player,tonef);
    PsychPortAudio('GetAudioData',ph.recorder);
    PsychPortAudio('GetAudioData',ph.recorder, toneDuration + recorderBuffer,toneDuration + recorderBuffer);
    
    % Record and play
    t.rec  = PsychPortAudio('Start',ph.recorder,1);
    t.play = PsychPortAudio('Start',ph.player,1);
    
    % Gather data and stop recorder
    tic; pause(toneDuration + recorderBuffer); toc
    [recTones{ii},~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
    PsychPortAudio('Stop',ph.recorder);
end

%% Record silence
%
% We briefly record some silence so that we can compare how loud our pure
% tones are. Clear and initialize buffers on the recording device as usual.
PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('GetAudioData',ph.recorder, toneDuration + recorderBuffer,toneDuration + recorderBuffer);
t.rec  = PsychPortAudio('Start',ph.recorder,1);
tic; pause(toneDuration + recorderBuffer); toc
[recSilence,~,~,t.recGet] = PsychPortAudio('GetAudioData',ph.recorder);
PsychPortAudio('Stop',ph.recorder);

% Calculate RMS of silence for loudness
[fb, fa] = butter(5, 2*300 / fs, 'high');
b = filter(fb, fa, recSilence * inGain);
b = b / rPa / vpPa;
b = b(.25*fs:end);
b = b - mean(b);
noise_ms = mean(b.^2);

%% Plot pure tones
%
% Calculate loudness of each filtered pure tone. Subtract silence.
RMS = zeros(size(recTones));
for ii = 1:length(recTones)
    tonesf = filtfilt(fb,fa,recTones{ii} * inGain);
    RMS(ii) = sqrt(mean( (tonesf(0.5 * fs:end-2*fs)/rPa/vpPa).^2)...
        - noise_ms);
end
db = real( 20*log10(RMS) );
plot(toneFs,db,'o')

%% Close audio devices
PsychPortAudio('Close');

%% Save plots, filter, and data

% filter filename
thedate = ['-' datestr(now,'YYmmDD')];
booth = ['booth' num2str(boothNumber)];
filtername = sprintf('%s%s-filter-%03dkHz',booth,thedate,fs/1e3);

% Save filter and figure
save('-6',[filtername '.mat'],'FILT')

xlabel('Frequency (Hz)')
ylabel('dB')
legend('Gaussian Noise','Filtered Noise','Filtered Tones','Location','southwest');
title(['calibration ' booth thedate])
print(filtername,'-dpng');

% 

