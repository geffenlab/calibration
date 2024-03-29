function s = startSession(fs,input,output)

s = daq.createSession('ni');

s.Rate = fs;

ai=addAnalogInputChannel(s,'dev1',input,'Voltage');
ao=addAnalogOutputChannel(s,'dev1',output,'Voltage');

s.Channels(1).InputType = 'SingleEnded';
