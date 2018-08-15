function [reps, P, f, dB] = getResponse_sess_SC(stim, nreps, s)

stim = stim/11;
% Some checks
if size(stim,2) == 1
    stim = stim';
end
if max(abs(stim)) > 10
    error('Stimulus is over 10V!!');
end

for i = 1:nreps
    disp(['Rep ' num2str(i) '/' num2str(nreps)])
%     output = [zeros(1,length(stim));stim];
    output = stim;
    PsychPortAudio('FillBuffer', s.h, output); % fill buffer
    t.play = PsychPortAudio('Start', s.h, 1);
    % Grab the data in the buffer at the end
    pause(5);
    [data, ~, ~, t.rec] = PsychPortAudio('GetAudioData', s.h);
    %     data = data(10000:80000);
    data = data*11;
    reps(i,:) = data - mean(data);
end

%repsM = mean(reps,1)/s.ref_Pa/s.VperPa/sqrt(2);
repsM = mean(reps,1)/s.ref_Pa/s.VperPa;
[P,f] = pwelch(repsM, 1024, 120/1024, [], s.fs, 'onesided');
dB = 10*log10(P);