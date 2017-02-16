function tone = genTone(f, tLen, rampTime, fs)
    
    len = tLen * fs + 4*rampTime;
    t = 0:(len-1);
    tone = sin(f * t/fs * 2*pi);
    ramp = sin((0:(rampTime-1))*pi/2 / rampTime).^2;
    tone = (tone .* [zeros(1, rampTime) ramp ones(1, tLen*fs)...
        fliplr(ramp) zeros(1,rampTime)])';