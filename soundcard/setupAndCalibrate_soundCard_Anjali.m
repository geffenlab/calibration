function [FILT, fs] = setupAndCalibrate_soundCard

% this function calibrates the speaker to have a flat response over a
% specified range of frequencies by making a FIR filter to account for the
% speakers frequency response function
% NOTE1: if you're savvy and know that to convert between DBspl of noise and DBspl
% of a pure tone, see notes about sqrt(2) conversion in makeFilter.m
close all
clear all
clc

io.fs = 192e3;
fs = io.fs;
io.ref_Pa=20e-6;
io.VperPa=0.316;
InitializePsychSound(1);pause(1); 
io.h = PsychPortAudio('Open', [], 3, 3, io.fs, [1 1]);

n = 2;
% offset = 10; % this is for when the output is too loud for the nidaq
% SCoffset = 10;
io.dur = 10;
targetVol = 70;
upperFreq = 50e3; %changed upperFreq from 80K to 50K - 01082025
lowerFreq = 3000;
softGain = 10; %the Amplitude factor - maybe change it for the lynx card.
ref_PA = 20e-6;
volts_per_PA = .316;
inGain = 11;
outGain=10.2;

[fb, fa] = butter(5, 2*300 / io.fs, 'high');

% preallocate recording buffer
PsychPortAudio('GetAudioData', io.h, io.dur);

disp('Testing flat noise');
% stim = softGain * randn(io.fs, 1)/sqrt(2)/10; % the sqrt factor was added
% incorrectly originally to compensate for SPL conversions between noise and
% tones.  Now compensation happens in getResponse_sess_SC
stim = softGain * randn(round(io.fs), 1)/10; %stim is between -2 and 2 here
% stim = stim.*10^(-(offset/20));
[resp, P, f, dB] = getResponse_sess_SC(stim,n,io);
resp = mean(resp);
f1 = figure(1); hold on
plot(f,dB,'r');
disp(['Total volume ' num2str(10*log10(mean(P)*(f(end)-f(1))))...
    'dB in response to flat noise.']);


FILT = makeFilter(P, f, io.fs, lowerFreq, upperFreq, targetVol);
disp('Testing filtered noise:');
% stim = softGain * randn(round(io.fs), 1)/10;
noisef = filter(FILT, 1, stim);
[resp, P, f, dB] = getResponse_sess_SC(noisef,n,io);
plot(f,dB);
disp(['Total volume ' num2str(10*log10(mean(P(1:180))*(f(180)-f(1))))...
    'dB in response to flat noise.']);

 disp(['Total volume ' num2str(20*log10(rms(mean(resp)/ref_PA/volts_per_PA)))...
     'dB in response to flat noise.']);

toneio.freqs = 2.^linspace(log2(3000),log2(50000), 5); %changed the frequency range-01082025_AS
[RMS, dBs] = toneResponse_SC(toneio.freqs, .1 * softGain, 1, FILT, io);
toneDB = real( 20*log10(RMS) );
plot(toneio.freqs, toneDB, 'ok');
xlabel('Frequency (kHz)')
ylabel('Power (dB)')
legend('unfiltered gaussian noise','filtered noise','tones','location','sw');
set(gca,'FontSize',12);
set(gca,'TickDir','out');
hold off

%
keyboard
fn = 'D:\GitHub\filters\250108_blueEbooth_LynxE44_3k-80k_fs192k_hiccup';
title(fn)
Fs = fs;
save(fn,'FILT','Fs');
print(f1,[fn '.png'],'-dpng','-r300');