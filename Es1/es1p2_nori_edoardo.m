%Generazione segnale P.A.M.
clear
close all
clc
 
fs=10000;     % frequenza di camp
Rs=230;      % symbol rate 
nbit=10000;   % lunghezza in bit del segnale
 
sc=round(fs/Rs);                % fattore di sovracamp. = campioni per simbolo
symbs=sign(rand(1,nbit)-0.5);   % generazione simboli (+1,-1) random
y=upsample(symbs,sc);           % segnale prima del formatore impulsi
x=filter(ones(1,sc),1,y);       % segnale P.A.M. a valle del formatore
plot(x(1:1000)),xlabel('n'),ylabel('x_n'),title('Primi 1000 campioni');

% Punto 2.a
N = [128, 1024, 2^14];
xoss1 = x(1:N(1));
xoss2 = x(1:N(2));
xoss3 = x(1:N(3));


freq1 = 0:fs/N(1):(N(1)-1)*fs/N(1);
sTeorica1 = (1/Rs)*(sinc(freq1/Rs).^2);
S1 = (1/(N(1)*fs))*(abs(fft(xoss1)).^2);
figure
subplot(3,1,1);
hold on
plot(freq1, sTeorica1);
plot(freq1, S1);
hold off
xlim([0 800]);
xlabel("Frequencies [Hz]");
ylabel("PSD est. module [V^{2}/Hz]");

freq2 = 0:fs/N(2):(N(2)-1)*fs/N(2);
sTeorica2 = (1/Rs)*(sinc(freq2/Rs).^2);
S2 = (1/(N(2)*fs))*(abs(fft(xoss2)).^2);
subplot(3,1,2);
hold on
plot(freq2, sTeorica2);
plot(freq2, S2);
hold off
xlim([0 800]);
xlabel("Frequencies [Hz]");
ylabel("PSD est. module [V^{2}/Hz]");

freq3 = 0:fs/N(3):(N(3)-1)*fs/N(3);
sTeorica3 = (1/Rs)*(sinc(freq3/Rs).^2);
S3 = (1/(N(3)*fs))*(abs(fft(xoss3)).^2);
subplot(3,1,3);
hold on
plot(freq3, sTeorica3);
plot(freq3, S3);
hold off
xlim([0 800]);
xlabel("Frequencies [Hz]");
ylabel("PSD est. module [V^{2}/Hz]");
print(gcf,'punto2a.jpg','-djpeg','-r300');

% Punto 2.b
NFFT = 2^10;
[Pxx,frequenze]=pwelch(x,hanning(NFFT),[],NFFT,fs,'centered');
figure;
plot(frequenze, Pxx);
xlabel("Frequencies [Hz]");
ylabel("PSD estimate module [V^{2}/Hz]");
title("Power spectral density with pwelch");
grid on;
hold on 
sTeorica4 = (1/Rs)*(sinc(frequenze/Rs).^2);
plot(frequenze, sTeorica4);
xlim([-800 800]);

print(gcf,'punto2b.jpg','-djpeg','-r300');