%% SETUP
% params
n = 1;
offset = 0;
targetVol = 70-offset;
upperFreq = 70e3;
lowerFreq = 400;
fs = 192e3;
rPa=20e-6;
vpPa=0.316;
inGain = 6;
outGain = 11;

% setup non-ASIO LYNX card
device = 'Lynx E44';
d = daq.getDevices;
description = sprintf('DirectSound Speakers (%s)',device);
ind = find(strcmp({d.Description},description));
dev = d(ind);
s = daq.createSession('directsound');
ch = addAudioOutputChannel(s,dev.ID,1);
s.Rate = fs;
fs = s.Rate;

[fb, fa] = butter(5, 2*300 / fs, 'high');

% filter filename
thedate = ['-' datestr(now,'YYmmDD')];
booth = 'booth3';
fn = sprintf('%s%s-filter-%03dkHz',booth,thedate,fs/1e3);



%% PLAY flat noise
t = 10;
stim = randn(round(fs*t),1);
%stim = stim.*10^(-(offset/20));
queueOutputData(s,stim/outGain);
startBackground(s);

%% ANALYZE flat noise
noise = load(['flatNoise' thedate]);
%noise = load('file.mat');
%noiseAdj = mean(noise.saveData(1:end-1,1000:end-1000)*inGain,1)/rPa/vpPa;
noiseAdj = noise.saveData(1,1000:end-1000) * inGain / rPa / vpPa;
[P,f] = pwelch(noiseAdj,1024,120,[],fs,'onesided');
dB = 10*log10(P);
f1 = figure(1); clf; hold on
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);

% make a filter
FILT = makeFilter(P,f,fs,lowerFreq,upperFreq,targetVol);



%% PLAY filtered noise (20s)
noisef = conv(stim,FILT,'same');
queueOutputData(s,noisef/outGain);
startBackground(s);

%% ANALYZE filtered noise
fnoise = load(['filteredNoise' thedate]);
%fnoiseAdj = mean(fnoise.saveData(1:end-1,1000:end-1000)*inGain,1)/rPa/vpPa;
fnoiseAdj = fnoise.saveData(1,1000:end-1000) * inGain / rPa / vpPa;
[P,f] = pwelch(fnoiseAdj,1024,120,[],fs,'onesided');
dB = 10*log10(P);
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);
% 20*log10(rms(fnoiseAdj(2000:end)))



%% ANALYZE silence
% high pass filter and noise ms
[fb, fa] = butter(5, 2*300 / fs, 'high');
b = load(['silence' thedate]);
b = b.saveData(1,1000:end-1000) * inGain / rPa / vpPa;
b = filter(fb, fa, b);
b = b(.25*fs:end);
b = b - mean(b);
noise_ms = mean(b.^2);

%% PLAY tones
toneFs = 3500:5000:65000;
for i = 1:length(toneFs)
    f = toneFs(i);
    fprintf('Playing tone %02d/%02d @ %dHz\n',i,length(toneFs),f);
    t = tone(f,1,2,fs);
    t = envelopeKCW(t,5,fs);%.*10^(-(10/20));
    tonef = conv(t,FILT,'same');
    queueOutputData(s,tonef'/outGain);
    startForeground(s);
    pause(5);
end

%% ANALYZE tones
% load tone responses and compute db
tones = load(['tones' thedate]);
tones = tones.saveData * inGain;
for i = 1:size(tones,1)/2
    tonesf(i,:) = filtfilt(fb,fa,tones(2*i-1,:));
    RMS(i) = sqrt(mean( (tonesf(i,2000:end-2000)/rPa/vpPa).^2)...
        - noise_ms);
end
db = real( 20*log10(RMS) )
freqs = toneFs(1:end);
plot(freqs,db,'o')

%% save the filt file and calibration plot
xlabel('Frequency (Hz)')
ylabel('dB')
legend('Gaussian Noise','Filtered Noise','Filtered Tones','Location','sw');
title(['calibration ' booth thedate])
print(f1,fn,'-dpng','-r300');

save(fn,'FILT')



