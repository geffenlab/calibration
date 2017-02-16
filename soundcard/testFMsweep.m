clear all

fs = 100e3;
s = startSession(fs);
fs = s.Rate;
load('C:\calibration\Filters\20160825_2PspkrNidaqInvFilt_3k-70k_fs100k.mat');
n = 10;
targetVol = 70;
upperFreq = 70e3;
lowerFreq = 3000;
softGain = 10;
ref_PA = 20e-6;
volts_per_PA = .316;

global pm
pm.fs = 100000;
pm.stimParameters = table2cell(readtable('C:\Experiments\PASSIVE\FM_sweeps\FMsweepCalibration.txt','delimiter','\t'));
[stim,~] = FMsweep_stimgen;
stim = stim(1,:);

% stim = softGain * randn(fs, 1)/10;


[fb, fa] = butter(5, 2*300 / fs, 'high');


% Some checks
if size(stim,1) == 1
    stim = stim';
end
if max(abs(stim)) > 10
    error('Stimulus is over 10V!!');
end

stim = filter(FILT,1,stim);
queueOutputData(s,stim);
[S, time] = s.startForeground();
[fb, fa] = butter(5, 2*300 / fs, 'high');
S = filter(fb,fa,S);
t = S(5000:28000);
tt = t/ref_PA/volts_per_PA;
r = rms(tt);
dB = 20*log10(r)


