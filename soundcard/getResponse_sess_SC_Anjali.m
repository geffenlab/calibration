function [reps, P, f, dB] = getResponse_sess_SC(stim, nreps, s)
%this function gets data from mic of the audio from speaker -01072025 AS
outGain=10.2; %10.2 for single lynx soundcard
inGain = 11; %1/11 of inGain for the small recording booth at 4channel, 32bit, 192KHz sampling for recording
%stim = stim/11 
stim = stim/outGain; %edited 12172024: AS
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
    %data = data(10000:80000);
    %data = data*11;    
    data = data*inGain; %edited 12172024: AS
    reps(i,:) = data - mean(data); %to remove any DC offset component(maybe??)
end

%repsM = mean(reps,1)/s.ref_Pa/s.VperPa/sqrt(2);
repsM = mean(reps,1)/s.ref_Pa/s.VperPa;
[P,f] = pwelch(repsM, 1024, 120, [], s.fs, 'onesided');
dB = 10*log10(P);