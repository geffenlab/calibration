function [rms, dBs] = toneResponse_KWppiSC(freqs, amp, nReps, FILT, pa)

rms = zeros(1, length(freqs));
tLen = 0.2; % .2s tone + ramps = .4s tone
[fb, fa] = butter(5, 2*300 / pa.fs, 'high');

disp('Acquiring 3s of background noise:');
stim = zeros(1,3*pa.fs);
b = getResponse_sess_KWppiSC(stim,1,pa);
b = filter(fb, fa, b) / pa.ref_Pa / pa.VperPa;
b = b - mean(b);
noise_ms = mean(b.^2);

rampTime = 0.1*pa.fs;
dBs = cell(size(freqs));

for fInd = 1:length(freqs)
    f = freqs(fInd);
    
    disp(['Playing tone at frequency ' num2str(f) 'Hz'])
    
%     tone = amp * genTone(f, tLen, rampTime, pa.fs);
    t = tone(f,1,0.4,pa.fs);
    t = envelopeKCW(t,5,pa.fs);
    tonef = conv(t,FILT,'same');
%     tonef = filter(FILT, 1, t);
%     tonef= tonef.*10^(-(10/20));
    [resp,~,~,dB] = getResponse_sess_KWppiSC(tonef, nReps, pa);
    respf = filtfilt(fb,fa,resp);
    respf = respf(rampTime:(end-rampTime));
    respf = respf(15000:30000);
    rms(fInd) = sqrt(mean( (respf/pa.ref_Pa/pa.VperPa).^2 )...
        - noise_ms);
    dBs{fInd} = dB;
end

