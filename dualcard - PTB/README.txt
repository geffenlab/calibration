This folder has code for calibrating the behavior booth speakers using a 
machine that has two Lynx E44 sound cards installed. The code here uses the
PTB functions for audio playback and recording while the other directory 
uses the Matlab DAQ Toolbox.

Note that the code in this directory should be compatible with Octave as 
well.

This calibation uses the Windows DirectSound drivers. Make sure that you 
have gone into the audio settings in Windows and set the playback/sampling
rate to 192 kHz.