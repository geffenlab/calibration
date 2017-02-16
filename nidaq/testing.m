function testing

s = daq.createSession('ni');
ao=addAnalogOutputChannel(s,'dev1',[0 1],'Voltage');
s.Rate = 400e3;
fs = s.Rate;

stim(1,:) = genTone(10e3,70,fs*.005,fs).*.1;
stim(2,:) = zeros(length(stim(1,:)),1);
stim(2,1:fs*.01) = 1;

%conv(stim,filt,'same');




tic
queueOutputData(s,stim');
toc
s.startForeground();