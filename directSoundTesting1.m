clear all
close all
fs = 192e3;
%noise = randn(round(fs), 1)'/50;
noise = [zeros(1,fs) ones(1,fs)];
noise = repmat(noise,1,5)/2;

d = daq.getDevices;
ind = find(strcmp({d.Description},'DirectSound Speakers (2- Lynx E44)'));
%ind = find(strcmp({d.Description},'DirectSound Speakers (Lynx E44)'));
dev = d(ind);

s = daq.createSession('directsound');
channels = [1 2];
ch = addAudioOutputChannel(s,dev.ID,channels);
s.Rate = fs;

stim = zeros(length(channels),length(noise));
stim(2,:) = noise;
stim(1,:) = randn(1,length(noise))/50;

for i = 1
    tic
    queueOutputData(s,stim');
    toc
    startForeground(s);
end
    