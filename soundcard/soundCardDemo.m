% Setup function
fs = 192e3;
InitializePsychSound(1);pause(1); 
h = PsychPortAudio('Open', [], 1, 3, fs, 3);

% When you want to play sounds
output = someOutput;
PsychPortAudio('FillBuffer', h, output); % fill buffer
PsychPortAudio('Start', h, 1);