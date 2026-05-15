% Esempio di demodulazione FM da utlizzare in cascata a CaptureSave_IQ_samples.m
% Laboratorio di Reti di Sensori per l'Energia e l'Ambiente
% Laurea in Ingegneria elettronica per l'energia e l'informazione @ Cesena
% Alma Mater Studiorum - Università di Bologna
% Andrea Giorgetti 
% April 2018, Revised May 2021, Revised March 2022
clear; close all; clc

fs=916000;        
audio_fs=48000;
x=load('samplesIQcatturati.mat');
nomefileout='demodulatoIQ.wav';

Ir=x.samplesIQ';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) Graficare lo spettro (in dB/Hz) dell'inviluppo complesso del segnale.....
%[COMPLETARE]
NFFT=1024;
[Gi, freq] = pwelch(Ir, hanning(NFFT),[], NFFT, fs, "centered");
figure;
plot(freq, 10*log10(Gi));
xlabel("Frequency [Hz]");
ylabel("PSD of Ir [dB/Hz]");
title("PSD estimate of Ir samples with WOSA");
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) Filtraggio per selezionare lo spettro dell'emittente selezionata
%[COMPLETARE]
Rp = 1; % dB
As = 30; % dB
fp = 90e3; 
fa = 110e3;
f = [fp fa];
a = [1 0];

% calcolo di delta1 e delta2
dev = [(10^(Rp/20)-1)/(10^(Rp/20)+1) 10^(-As/20)];
% sintesi con parks-mcclellan
[n,fo,ao,w] = firpmord(f,a,dev,fs);
b = firpm(n,fo,ao,w);

% Verifica della maschera del filtro
[LPF, freq_lpf] = freqz(b,a,512,fs);
figure;
subplot(2,1,1);
plot(freq_lpf, 20*log10(abs(LPF)));
xlabel("Frequency [Hz]");
ylabel("Magnitude [dB]");
title("Frequency response of LPF")
subplot(2,1,2);
plot(freq_lpf, unwrap(angle(LPF)));
xlabel("Frequency [Hz]");
ylabel("Phase [rad]");

Ir_filt = filter(b,1,Ir);
[Gi_filt, freq_filt] = pwelch(Ir_filt,hanning(NFFT), [], NFFT, fs, "centered");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) Graficare lo spettro (in dB/Hz) dell'inviluppo complesso filtrato 
%[COMPLETARE]
figure;
plot(freq, 10*log10(Gi));
hold on;
plot(freq_filt, 10*log10(Gi_filt));
xlabel("Frequency [Hz]");
ylabel("Magnitude [dB/Hz]");
title("PSD estimate filtered");
legend('G_{Ir}', 'G_{Irfilt}');
grid on;
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) Aggiungere la parte di codice mancante per la demodulazione FM. Il segnale demodulato sarà contenuto in un vettore xdem.
%[COMPLETARE]
delta_f_max = 75e3;
kf = delta_f_max/(max(abs(Ir_filt)));
T = 1/fs;
xdem = angle(Ir_filt(2:end,1).*(conj(Ir_filt(1:end-1,1)))) / (2*pi*kf*T);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) Graficare lo spettro (in dB/Hz) del segnale demodulato xdem. (multiplex FM)
%[COMPLETARE]
NFFT = 4096;
[G_xdem, freq] = pwelch(xdem, hanning(NFFT), [], NFFT, fs);
figure;
plot(freq, 10*log10(G_xdem));
hold on;
xlabel("Frequency [Hz]");
ylabel("Magnitude [dB/Hz]");
% title("PSD estimate of demodulated signal xdem");
grid on;
% xlim([0 60e3]); % è già presente nel punto 7

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6) Filtrare il segnale L+R (equivalente mono). 
%[COMPLETARE]
Rp = 1;
As = 30;
fp = 15e3;
fa = 18e3;

f = [fp, fa];
a = [1 0];

% calcolo di delta1 e delta2
dev = [(10^(Rp/20)-1)/(10^(Rp/20)+1) 10^(-As/20)];
% sintesi con parks-mcclellan
[n,fo,ao,w] = firpmord(f,a,dev,fs);
b2 = firpm(n,fo,ao,w);

[LPF2, freq2] = freqz(b2,1,512,fs);

% figure;
% subplot(2,1,1);
% plot(freq2, 20*log10(abs(LPF2)));
% xlabel("Frequency [Hz]");
% ylabel("Magnitude [dB]");
% title("Frequency response of LPF2");
% xlim([0 20e3]);
% subplot(2,1,2);
% plot(freq2, unwrap(angle(LPF2)));
% xlabel("Frequency [Hz]");
% ylabel("Phase [rad]");
% xlim([0 20e3]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7) Graficare lo spettro (in dB/Hz) del segnale demodulato e filtrato. 
%[COMPLETARE] 
xdem_filt = filter(b2,1,xdem);
[Gi_xdem_filt, freq] = pwelch(xdem_filt, hanning(NFFT), [], NFFT, fs);
plot(freq, 10*log10(Gi_xdem_filt));
xlabel("Frequency [Hz]");
ylabel("Magnitude [dB/Hz]");
title("PSD estimate of demodulated and filtered (and not) signal xdem");
legend('Not filtered', 'Filtered');
grid on;
xlim([0 20e3]);
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ascolto del segnale demodulato previa scrittura su file .wav 
% (GIA' FATTO!!!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xdem_mono = xdem_filt;
% Si riduce la freq di campionamento per la scheda audio
y=resample(xdem_mono,audio_fs,fs);

% Si adatta l'ampiezza per il formato wav
y=0.8*y/max(abs(y));

% Salvataggio del segnale demodulato
audiowrite("demodulatoIQ.wav",y,audio_fs);