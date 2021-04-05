% reset everything
delete(instrfindall);
close all
clear

% load the filter
FILT = load('D:\GitHub\filters\20210324_OpenEphys_3k-60k_fs200k_N1_NV.mat');

% connect to the nidaq (CHECK THE INPUT/OUTPUT CHANNELS)
fs = FILT.Fs;
input = 0;
output = 0;
s = startSession(fs,input,output);
fs = s.Rate;
disp(['fs = ' num2str(fs)])
ref_PA = 20e-6;
volts_per_PA = .316;

%% Get background/mic noise
[fb, fa] = butter(5, 300 / (fs/2), 'high'); % to remove very low frequency noise
% nstim = zeros(1,10*fs);
% b = getResponse_sess(nstim,1,s);
% b = filtfilt(fb,fa,b);
% brms = rms(b/volts_per_PA);

%% MAKE THE STIM
bandwidth = [3000 60000]; % kHz
stim = (randn(fs*5,1)); % 1 second noise
% stim = zeros(fs*5,1);
% stim = tone(28000,1,5,fs);
stim = envelopeKCW(stim,5,fs);
% [A,B,C,D] = butter(10,bandwidth/(fs/2));
% [SOS,G] = ss2sos(A,B,C,D);
% stim = filtfilt(SOS,G,stim);
% spectrogram(stim(1:fs),1024,512,1000:1000:100000,fs)
stimf = conv(stim,FILT.FILT,'same');

%% PRESENT AND RECORD THE STIM
% Get level after filter:
[resp, P, f, dB] = getResponse_sess(stimf,1,s);
resp = filtfilt(fb,fa,resp);
% resp = resp-mean(resp);
plot(f,dB); hold on
baseline_level = real(20*log10((rms(resp/volts_per_PA))/ref_PA));
disp(['Baseline volume ' num2str(baseline_level) 'dB SPL']);
title(sprintf('baseline dB = %0.1f',baseline_level))
%%
levels = fliplr([50:5:80]);
% levels = randsample(levels,length(levels),false)
level_changes = levels-baseline_level;
dbspl = zeros(1,length(level_changes));
for ii = 1:length(level_changes)
    stim_ch = stim.*10^(level_changes(ii)/20);
    stimf = conv(stim_ch,FILT.FILT,'same');
    [resp, P, f, dB] = getResponse_sess(stimf,1,s);
    resp = filtfilt(fb,fa,resp);
    dbspl(ii) = real(20*log10((rms(resp/volts_per_PA))/ref_PA));
end
figure
plot(baseline_level+level_changes,dbspl,'x-')
xlabel('Expected dB SPL')
ylabel('Measured dB SPL')
title(sprintf('3-60kHz, baseline dB = %0.1f',baseline_level))