function testStimLevel

load('tones');
load('nitay_stim');
fstim = load('SMALL_BOOTH_FILT_70dB_200-9e3kHZ');

keyboard

fs = 400e3;
s = startSession(fs);
fs = s.Rate;

[fb, fa] = butter(5, 2*300 / fs, 'high');


% play, HP filter, and measure noise dB
noisef = filter(fstim.filt,1,10*stim{1});
[nResp, nP, f, ndB] = getResponse_sess(noisef,1,s);
resp = filter(fb,fa,nResp);
[nP,f] = pwelch(resp/20e-6/.316,1024, 120, [], fs, 'onesided');

figure(2); hold on;
plot(f,ndB,'r');
filtNoiseDB = 10*log10(mean(nP) * (f(end) - f(1)));
fprintf('Filtered noise: %g dB\n',filtNoiseDB);
keyboard
% test tones
ref_Pa = 20e-6;
volts_per_Pa = .316;

disp('Acquiring 3s of background noise:');
stim = zeros(1,3*fs);
b = getResponse_sess(stim,1,s);
b = filter(fb, fa, b) / ref_Pa / volts_per_Pa;
b = b - mean(b);
noise_ms = mean(b.^2);

for i = 1:length(signals)
    [resp,~,~,dB] = getResponse_sess(tonef, nReps, pa);
    respf = filter(fb,fa,resp);
    respf = respf(10000:end-10000);
    RMS(i) = sqrt(mean( (respf/ref_Pa/volts_per_Pa).^2 )...
        - noise_ms);
end
toneDB = real(20*log10(RMS));

