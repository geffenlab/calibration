function [reps, P, f, dB] = getResponse_sess(stim, nreps, s)

% Some params
ref_PA = 20e-6;
volts_per_PA = .316;
fs = s.Rate;


% Some checks
if size(stim,1) == 1
    stim = stim';
end
if max(abs(stim)) > 10
    error('Stimulus is over 10V!!');
end

for i = 1:nreps
    queueOutputData(s,stim);
    dur = s.DurationInSeconds;
    fprintf('\tTrial %g - %g sec\n',i,dur);
    [S, time(i,:)] = s.startForeground();
    reps(i,:) = S - mean(S);
end

%repsM = mean(reps,1)/ref_PA/volts_per_PA/sqrt(2);
repsM = mean(reps,1)/ref_PA/volts_per_PA;
[P,f] = pwelch(repsM, 1024, 120, [], fs, 'onesided');
dB = 10*log10(P);