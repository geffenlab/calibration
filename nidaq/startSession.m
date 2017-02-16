function s = startSession(fs)

s = daq.createSession('ni');

s.Rate = fs;

ai=addAnalogInputChannel(s,'dev1',1,'Voltage');
ao=addAnalogOutputChannel(s,'dev1',0,'Voltage');

s.Channels(1).InputType = 'SingleEnded';
