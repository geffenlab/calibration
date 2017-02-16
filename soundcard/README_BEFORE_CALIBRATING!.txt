For running speaker calibrations...

Run('C:\Users\Maria\Documents\MATLAB\Calibration\20160921_PPIspkrCalibration\setupAndCalibrate_KW_PPIchamberSoundCard.m')

This creates a filter for the sound card.  The sound card requires a correction of X11 (built into the above code).

NB. You must divide your outputs by 11.  Use the function, presentStim.m for this to be automatic.

- FILT output is the filter



