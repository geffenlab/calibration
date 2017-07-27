fs = 192e3;
rPa = 20e-6;
vpPa = 316e-3;

%% record silence then test tone
% high pass filter
[fb, fa] = butter(5, 2*300 / fs, 'high');
ampF = 6.25;
b = load('silence.mat');
b = b.saveData(end,:)*ampF;
b = filter(fb, fa, b) / rPa / vpPa;
b = b(.25*fs:end);
b = b - mean(b);
noise_ms = mean(b.^2);

% load tone responses and compute db
%tone = load('tones.mat');

tt = load('94dbTest.mat');
%tt = load('114dbTest.mat');
d = tt.saveData(end,:)*ampF;
df = filter(fb,fa,d);
df = df(.25*fs:end);
df = df - mean(df);
RMS = sqrt(mean((df/rPa/vpPa).^2) - noise_ms);
db = 20*log10(RMS)


d = load('sineTest-booth3.mat');
d = d.saveData(1,:);
ampF = 1/max(d);


SC1 = 6.2575
SC2 = 6.3111