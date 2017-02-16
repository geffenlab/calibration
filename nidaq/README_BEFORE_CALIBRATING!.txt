For running speaker calibrations...

Run('C:\calibration\20160825calibration_2PboothNIDAQ\setupAndCalibrate_CA.m')

ensure that the nidaq card is set up appropriately with the mic and output speakers on channels as in startSession.m in the same folder as above.


- The function outputs noise with +/- 1V
- It records that noise through the nidaq card, applying corrections for the microphone amplifier
- A filter is then made to correct the amplitude of the noise to the target volume
	- The target volume refers to the target volume of the tones and since noise has a lower dB SPL than tones by 20*log10(sqrt(2)) dB, this correction is applied to the target volume in the makeFilter function

- The code then tests this filter on various tones and plots their output dB

- FILT output is the filter




THEREFORE

When using this code, one does NOT need to correct the rms of the noise by the sqrt(2) factor.

the sqrt(2) factor should never be corrected for when calculating the rms of tones.


