function [rms, dBs] = toneResponse_KWppiSC(freqs, amp, nReps, FILT, pa)

% Parameters
fs = pa.Rate;
ref_Pa = 20e-6;
volts_per_Pa = .316;

rms = zeros(1, length(freqs));
tLen = 0.2; % .2s tone + ramps = .4s tone
[fb, fa] = butter(5, 2*300 / fs, 'high');

disp('Acquiring 3s of background noise:');
stim = zeros(1,3*fs);
b = getResponse_sess(stim,1,pa);
b = filter(fb, fa, b) / ref_Pa / volts_per_Pa;
b = b - mean(b);
noise_ms = mean(b.^2);

rampTime = 0.1*fs;
dBs = cell(size(freqs));

for fInd = 1:length(freqs)
    f = freqs(fInd);
    
    disp(['Playing tone at frequency ' num2str(f) 'Hz'])
    
    tone = amp * genTone(f, tLen, rampTime, fs);
    tonef = filter(FILT, 1, tone);
%     tonef= tonef.*10^(-(10/20));
    [resp,~,~,dB] = getResponse_sess(tonef, nReps, pa);
    respf = filtfilt(fb,fa,resp);
    respf = respf(rampTime:(end-rampTime));
    rms(fInd) = sqrt(mean( (respf/ref_Pa/volts_per_Pa).^2 )...
        - noise_ms);
    dBs{fInd} = dB;
end

