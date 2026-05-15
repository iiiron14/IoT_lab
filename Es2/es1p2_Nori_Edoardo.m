clear;close all;clc;

A = 1+3; % ultimo numero di matricola = 3;
b_len = A + 2;
fs = 20e3;
T = 1/fs;
b = zeros(1,b_len) + 1/A;

% punto 1
[H, freq] = freqz(b, 1, 512, fs);
figure;

subplot(2,1,1);
plot(freq, 20*log10(abs(H)));
xlabel("Frequencies [Hz]")
ylabel("Magnitude of FIR filter ");
grid on;
title("Frequency response of FIR filter");
subplot(2,1,2);
plot(freq, angle(H));
xlabel("Frequencies [Hz]");
ylabel("Phase of FIR filter");
grid on;
print(gcf,'punto1es2.jpg','-djpeg','-r300');