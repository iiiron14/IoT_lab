% Genera un segnale campionato in Volt composto da due sinusoidi di
% ampiezze A1 e A2 a frequenze f1 e f2 e AWGN con potenza sigma^2

clear 
close all
clc
A1=3;
A2=3;
f1=1000;
f2=1030;
fs=10000;
T = 1/fs;
sigma2=0.5;
lun=50000;
tempo=0:T:T*lun-T;
x = A1*cos(2*pi*f1*tempo) + A2*cos(2*pi*f2*tempo) + randn(1,lun)*sqrt(sigma2);

% Punto 1.a
figure;
plot(tempo(1:1000), x(1:1000));
xlabel('Time (s)');
ylabel('Amplitude (V)');
title('Signal composed of two sinusoids with AWGN');
grid on;
print(gcf,'punto1a.jpg','-djpeg','-r300');

% Punto 1.b
N = [128, 1024, 2^14];
xosservato1 = x(1:N(1));
xosservato2 = x(1:N(2));
xosservato3 = x(1:N(3));
% M=2^14;
S1 = (1/(N(1)*fs))*(abs(fft(xosservato1)).^2); % per lo zero-padding cambiare in fft(xosservato1, M)
freq1 = 0:fs/N(1):(N(1)-1)*fs/N(1);
% freq1=0:fs/M:(M-1)*fs/M; % zero-padding
figure
plot(freq1, 10*log10(S1));
hold on

S2 = (1/(N(2)*fs))*(abs(fft(xosservato2)).^2);
freq2 = 0:fs/N(2):(N(2)-1)*fs/N(2);
plot(freq2, 10*log10(S2));

S3 = (1/(N(3)*fs))*(abs(fft(xosservato3)).^2);
freq3 = 0:fs/N(3):(N(3)-1)*fs/N(3);
plot(freq3, 10*log10(S3));

hold off
xlabel("Frequencies [Hz]");
ylabel("PSD estimates modules [dB]");
legend('N = 128', 'N = 1024', 'N = 2^{14}');
title('Power Spectral Density Estimates');
grid on;
% xlim([500 1500]);

print(gcf,'punto1b.jpg','-djpeg','-r300');