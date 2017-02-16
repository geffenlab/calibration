function testSpeakers(speakerID)

clear all
close all
speakerID = 'MF1';

% Get Isaac's functions
addpath('C:\Code\SpeakerTest');

% Start DAQ session
disp('Starting DAQ...');
s = startSession;

% Parameters
fs = s.Rate;
bandwidth = 500;
ref_PA = 20e-6;
volts_per_PA = .316;

% Make a high pass filter
[fb, fa] = butter(5, 2*300 / fs, 'high');

% Get baseline noise response over 3s and high pass filter
disp('Getting noise baseline...');
[~, noise, ~, ~, ~] = getResponse_sess(zeros(1,3*fs), 1, s);
noise = filter(fb,fa,noise);

% For a bunch of frequencies
freqs = 1000:5000:106000;
amps = [.9];
for j = 1:length(amps)
    for i = 1:length(freqs)
        
        fprintf('Playing frequency %g\n', freqs(i));
        
        % Make a stimulus, play it, record it, filter it
        tLen = .2;
        rLen = .05 * fs;
        stim(i,:) = amps(j) * genTone(freqs(i), tLen, rLen, fs);
        [t, resp, ~, ~, ~] = getResponse_sess(10*stim(i,:), 1, s);
        r{j}(i,:) = resp;
        resp = filter(fb, fa, resp./ref_PA./volts_per_PA);
        tone(i,:) = resp(rLen:end-rLen);
        
        
        % Estimate dB across entire range
        [P(i,:),f] = pwelch(tone(i,:), 1024, 120, [], fs, 'onesided');
        dB(i,:) = 10*log10(P(i,:));
        dbEst(i,:) = 10*log10(mean(P(i,:))*(f(end)-f(1)));
        
        % Check if power changes depending on the length of the tone
        [P2, f2] = pwelch(tone(i,1:length(tone(i,:))/2), 1024, 120, [], fs, 'onesided');
        %     hold on
        %     plot(f,P)
        %     plot(f2,P2,'r')
        %     hold off
        
        
        % dB level using mean power
        fRange = [1e3 80e3];
        dbMP(i) = 10*log10(mean(P(i,:))*(fRange(end)-fRange(1)));
        
        % dB level using RMS subtracting the noise RMS
        rms(i) = sqrt(mean(tone(i,:) .^ 2) - mean(noise .^ 2));
        dbRMS(i) = real(20*log10(rms(i)));
        
        rms2(i) = sqrt(mean(tone(i,:) .^ 2));
        dbRMS2(i) = real(20*log10(rms2(i)));
    end
end

figure(1)
hold on
set(gca,'Fontsize',16)
h(1) = plot(freqs/1e3,dbEst,'k');
h(2) = plot(freqs/1e3,dbRMS,'r');
h(3) = plot(freqs/1e3,dbRMS2,'g');
h(4) = plot(freqs/1e3,dbMP,'b');
xlabel('Frequency (kHz)');
ylabel('dB SPL');
ylim()
title('TDT Amp Multicomp Tweet - Ganged Output (.9 Amplitude)','FontWeight','Bold');
legend('Mean Power - all','RMS','RMS w. noise','Mean Power - band');
hold off

figure(2)
set(gca,'FontSize',12)
for i = 1:length(freqs/1e3)
    subplot(5,5,i)
    plot(f/1e3,dB(i,:))
    title(sprintf('%g kHz Tone Response',freqs(i)/1e3));
    if i == length(freqs/1e3)-1
    xlabel('Frequency (kHz)');
    ylabel('dB SPL');
    end
    ylim([-50 100])
end
a = suptitle('TDT Amp Multicomp Tweet - Ganged Output (.9 Amplitude)');
set(a,'FontWeight','Bold')

plot_amps = 0;
if plot_amps
    figure(3)
    hold all
    for j = 1:length(amps)
        h1(j) = plot(freqs,max(abs(r{j}),[],2));
    end
    xlabel('Frequency')
    ylabel('Max Amp.');
    title('Raw Amp Output');
    legend(h1,'.01V','.05V','.1V','.5V','.9V','Location','NE');
end
keyboard





