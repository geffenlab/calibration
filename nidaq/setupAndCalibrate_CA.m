function [FILT, fs, s] = setupAndCalibrate_CA

% this function calibrates the speaker to have a flat response over a
% specified range of frequencies by making a FIR filter to account for the
% speakers frequency response function
% NOTE1: if you're savvy and know that to convert between DBspl of noise and DBspl
% of a pure tone, see notes about sqrt(2) conversion in makeFilter.m
delete(instrfindall);
close all
clear all

fs = 400e3;
s = startSession(fs);
fs = s.Rate;

n = 5;
offset = 0; % this is for when the output is too loud for the nidaq
targetVol = 70-offset;
upperFreq = 80e3;
lowerFreq = 3000;
softGain = 10;
ref_PA = 20e-6;
volts_per_PA = .316;

[fb, fa] = butter(5, 2*300 / fs, 'high');

disp('Testing flat noise');
% stim = softGain * randn(fs, 1)/sqrt(2)/10; % the sqrt factor was added
% incorrectly originally to compensate for SPL conversions between noise and
% tones.  Now compensation happens in getResponse_sess
stim = softGain * randn(round(fs*20), 1)/10;
stim = stim.*10^(-(offset/20));
[resp, P, f, dB] = getResponse_sess(stim,n,s);
resp = mean(resp);
figure(1); hold on
plot(f,dB,'r');
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);


FILT = makeFilter(P, f, fs, lowerFreq, upperFreq, targetVol);
disp('Testing filtered noise:');
stim = softGain * randn(round(fs), 1)/10;
noisef = filter(FILT, 1, stim);
[resp, P, f, dB] = getResponse_sess(noisef,n,s);
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P(1:180))*(f(180)-f(1))))...
    'dB in response to flat noise.']);

 disp(['Total volume ' num2str(20*log10(rms(mean(resp)/ref_PA/volts_per_PA)))...
     'dB in response to flat noise.']);

toneFs = 3500:5000:80000;
[RMS, dBs] = toneResponse(toneFs, .1 * softGain, 1, FILT, s);
toneDB = real( 20*log10(RMS) );
plot(toneFs, toneDB, 'ok');
hold off

%
% save('E:\calibration\Filters\20170711_2PspkrNidaqInvFilt_3k-80k_fs400k.mat','FILT')