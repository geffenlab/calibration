function F = makeFilter(Pin, f, fs, flow, fhigh, targetVol)
% NOTE: in order to account for the fact that 70dBspl of noise is
% 20*log10(sqrt(2)) dB lower than 70dB of a pure tone, we applied a
% correction to the target volume.

df = f(2) - f(1);
targetPowerDensity = 10.^((targetVol+20*log10(sqrt(2)))/10) ./ (f(end) - f(1)); % convert from dB to power
% targetPowerDensity = 10.^(targetVol/10) ./ (f(end) - f(1)); % convert from dB to power

% Scale the frequency to identify the smoothing filter function to cutoff
% above 80khz.
f1 = (f-fhigh*1.01)/(0.01*fhigh);                   % makes a scaled frequency vector
erff = -1/2*(erf(f1))+.5;                           % makes a high cutoff
lowCut = [sin(f(f<=flow) * pi / 2 / flow).^2;...    % makes a low cutoff
    ones(sum(f>flow), 1) ];
invPowerIn = targetPowerDensity ./ Pin;             % makes an inverse power spectrum scaled by desired volume
invamp = sqrt(invPowerIn) .* erff .* lowCut;        % masks the inverted spectrum to desired f range and also converts it to amplitude (sqrt)

F = fir2(6000, 2*f/fs, invamp);                     % makes the FIR filter (order = 6000, f scaled between 0 and 1, inverted amplitudes)