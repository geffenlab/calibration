function [rms, dBs] = toneResponseByAmp(freq, amps, nReps, filt, pa)

% Parameters
fs = pa.Rate;
ref_Pa = 20e-6;
volts_per_Pa = .316;

rms = zeros(1, length(amps));
tLen = 0.2; % .2s tone + ramps = .4s tone
[fb, fa] = butter(5, 2*300 / fs, 'high');

disp('Acquiring 3s of background noise:');
stim = zeros(1,3*fs);
b = getResponse_sess(stim,1,pa);
b = filter(fb, fa, b) / ref_Pa / volts_per_Pa;
b = b - mean(b);
noise_ms = mean(b.^2);

rampTime = 0.1*fs;
dBs = cell(size(amps));

for i = 1:length(amps)
    
    disp(['Playing tone at amp ' num2str(amps(i))])
    
    tone = amps(i) * genTone(freq, tLen, rampTime, fs);
    tonef = filter(filt, 1, tone);
    [resp,~,~,dB] = getResponse_sess(tonef, nReps, pa);
    respf = filter(fb,fa,resp);
    respf = respf(rampTime:(end-rampTime));
    rms(i) = sqrt(mean( (respf/ref_Pa/volts_per_Pa).^2 )...
        - noise_ms);
    dBs{i} = dB;
end

