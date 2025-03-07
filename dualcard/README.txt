## readme for calibrating soundcards using the windows directsound driver ##

General Procedure:
1. Use one soundcard to record, the other to play stimuli
(the playback sound card is the one being calibrated)
2. Calibrate the playback card, then switch the mic to the playback card
(it is now the recording card, to calibrate the previous recording card)
3. recordCalibrationStim.m plays the stimuli,
softwareAnalogTriggerCaptureSave.m records the stimuli

** BEFORE STARTING **
Install Lynx drivers.
1. If drivers are already installed, uninstall them.
2. Reboot, and then install driver build 23b: https://www.lynxstudio.com/downloads/aes16e/windows-driver-v2-build-23b/
3. Download and install the firmware updater: https://www.lynxstudio.com/downloads/aes16e/firmware-updater-20150225-for-pcie-aes16e-e22-e44-and-thunderbolt/
4. Run the firmware update, selecting card 1 (it will ask for a serial number, this can be found on the card or on the box).
5. Shut down when prompted, power back on.
6. Run the firmware update again, selecting card 2. Shut down and restart the computer again.
7. Open the Lynx Mixer and set the sample rate (clock source) to 192kHz for each card (each card will have its own tab on the left).
8. Install Matlab suppot package to run soundcards: https://www.mathworks.com/hardware-support/sound-card-daq.html

You need to make sure that windows is using the desired sample rate. For some reason, 
Matlab's specification of the sample rate is overridden by the windows settings.
(it sucks, because matlab will say it is playing/recording at the sample rate you ask of it, 
but the actual recording rates are controlled by the rate setting in windows)

To check this:
1. Right click the sound icon on the left side of the windows toolbar
2. Click Playback Devices. Click Speakers (Lynx E44) and go to properties>advanced tab
3. Under default format, set this to 16 bit, 192000 Hz; hit apply and OK
4. Repeat steps 2-3 for Speakers (2- Lynx E44)
5. Repeat steps 1-4, but click Recording Devices and adjust advanced settings for
Record 01 + 02 (for each card, 2- Lynx E44 and Lynx E44) to 2 channel, 16 bit, 192000 Hz


Specific Procedure:
1. Open two instances of matlab, one running softwareAnalogTriggerCaptureSave.m,
the other running recordCalibrationStim.m
2. Make sure the device in each script is set to the proper card
(ie. if the mic is plugged into the input of the card in the 2nd PCI port, 
you want the device in softwareAnalogTriggerCaptureSave.m to be '2- Lynx E44'
and the device in recordCalibrationStim.m to be 'Lynx E44')
3. Start the analog capture script to record 10s of stimuli by setting capture.TimeSpan = 10
4. Once the analog capture GUI opens, set the file name to 'flatNoise'
5. Run the first section of recordCalibrationStim.m, making sure that booth = the correct 
string of the booth you're playing to/recording from
6. If your analog capture gui is running in the other matlab instance, start play back of 
gaussian noise by running the 'PLAY flat noise' section
7. Once this finishes, stop the analog capture GUI by quitting out
8. Run the 'ANALYZE flat noise' section to make a filter
9. Reopen another analog capture session, this time make the filename 'filteredNoise'
10. Run the 'PLAY filtered noise' section in the playback matlab instance
11. Once this finishes, stop the analog capture GUI by quitting out
12. Run the 'ANALYZE filtered noise' section to plot the flattened noise
13. Record some silence by opening a new capture session, setting the filename to 'silence'
and setting the trigger settings to Level = .00001 and Slope = 10
14. After one 10s capture, quit the capture session GUI
15. Run the 'ANALYZE silence' section in the playback matlab instance
16. Set the capture time in softwareAnalogTriggerCaptureSave.m to 1s by setting
capture.TimeSpan = 1
17. Reopen another analog capture session, this time make the filename 'tones'
18. Play the tones by running the 'PLAY tones' section in the playback matlab instance
19. Once this finishes (it will take a few minutes), determine the tone levels by running
the 'ANALYZE tones' section 
20. If everything in the plot looks good, save the filter file and the plot by running the
last section of code in the playback matlab instance
21. Be sure to move the filter file to GitHub/filters/

