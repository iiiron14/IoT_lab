clear; close all; clc;
fs = 20e3;
% definizione della maschera
rp = 3;             % Pass-band ripple in dB
rs = 40;            % Stop-band attenuation in dB
fp = 1000+3*200;    % ultimo numero di matricola = 3;
f = [fp, fp+100];   % Cut-off frequencies
a = [1 0];          % Desired amplitudes

% Calcolo di delta1 e delta2
dev = [(10^(rp/20)-1)/(10^(rp/20)+1), 10^(-rs/20)];

% sintesi con parks-mcclellan
[n,fo,ao,w] = firpmord(f,a,dev,fs);
b = firpm(n,fo,ao,w);

[H, freq] = freqz(b,1,512,fs);
figure;
subplot(2,1,1);
plot(freq, 20*log10(abs(H)));
title("Frequency response of FIR filter");
xlabel("Frequencies [Hz]");
ylabel("Magnitude [dB]");

subplot(2,1,2);
plot(freq, unwrap(angle(H)));
xlabel("Frequencies [Hz]");
ylabel("Phase [rad]");
print(gcf,'punto2es2.jpg','-djpeg','-r300');


% ultimo punto
% load("segnale.mat");
load("segnale.mat");
xin = segnale;

% Spettro del segnale in ingresso
NFFT = 2^10;
[Pxx, freq] = pwelch(xin, hanning(NFFT), [], NFFT, fs, 'centered');
figure;
subplot(2,1,1);
plot(freq, 10*log10(abs(Pxx)));
xlabel("Frequencies [Hz]");
ylabel("Magnitude [dB]");
title("PSD estimate module in-signal");
grid on;

x_out = filter(b,1,xin);
[Pxx_out, freq] = pwelch(x_out, hanning(NFFT), [], NFFT, fs, 'centered');
subplot(2,1,2);
plot(freq, 10*log10(abs(Pxx_out)));
xlabel("Frequencies [Hz]");
ylabel("Magnitude [dB]");
title("PSD estimate module out-signal");
grid on;

print(gcf,'punto3es2.jpg','-djpeg','-r300');