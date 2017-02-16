function filt = noiseCalibration
%% Try measuring SNR
% Measure the rms of our tone relative to the rms of the noise to estimate
% SNR ratio

% first setup the speaker
[filt, fs, s] = setupAndCalibrate_CA;

% params
softGain = 10;
dbSteps = [-20 -15 -10 -5 0];
duration = 3;
rampDuration = .01;
noiseAttenuation = 10;
signalAttenuation = [inf 1 ./ (1/noiseAttenuation .* 10.^(dbSteps/20))];

% make the noise
noise = randn(duration*fs,1)/sqrt(2)/10;
noisef = filter(filt,1,softGain * noise);

% high pass filter
[fb, fa] = butter(5, 2*300 / fs, 'high');

% play, HP filter, and measure noise dB
[nResp, nP, f, ndB] = getResponse_sess(noisef,1,s);
resp = filter(fb,fa,nResp);
[nP,f] = pwelch(resp/20e-6/.316,1024, 120, [], fs, 'onesided');

figure(2); hold on;
plot(f,ndB,'r');
filtNoiseDB = 10*log10(mean(nP) * (f(end) - f(1)));
fprintf('Filtered noise: %g dB\n',filtNoiseDB);

% now test different tone levels
amps = .1 .* 10.^(dbSteps./20);
[RMS,~] = toneResponseByAmp(10e3, amps * softGain, 1, filt, s);
toneDB = real(20*log10(RMS));

plot(repmat(10e3,1,length(dbSteps)),toneDB,'o');

keyboard
















% % make the noise
% noise = rand(1,duration*fs)*2 - 1;
% noise = noise * (1/noiseAttenuation);
% noisef = filter(filt,1,softGain * noise);
% 
% % play, HP filter, and measure noise dB
% WaitSecs(5)
% [nResp, nP, f, ndB] = getResponse_sess(noisef,1,s);
% figure(2); hold on;
% plot(f,ndB,'r');
% dBTot = 10*log10(mean(nP) * (f(end) - f(1)))
% 
% % Target db
% noiseTarget = 70;
% newAttenuation = noiseAttenuation * 10^((dBTot-noiseTarget)/10);
% noise = rand(1,duration*fs)*2 - 1;
% noise = noise * (1/newAttenuation);
% noisef = filter(filt,1,softGain * noise);
% [nResp, nP, f, ndB] = getResponse_sess(noisef,1,s);
% 
% plot(f,ndB);
% dBTot = 10*log10(mean(nP) * (f(end) - f(1)))
% 
% keyboard




















