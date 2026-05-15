%% ============================================================
%  ESERCITAZIONE MATLAB - UWB RFID con multi-tag
% Anna Guerra                                                               %
% Dip. di Ingegneria dell' Energia Elettrica e                              %
% dell'Informazione "Guglielmo Marconi" (DEI)                               %
% Alma Mater Studiorum - Università di Bologna                              %
% April 2026                                                                %
% Laboratorio IoT                                                           %
% Laurea in Ingegneria Elettronica per l'Energia e l'Inform. @ Cesena       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; clc;
%% ============================================================
% PARAMETRI DI SIMULAZIONE
%% ============================================================
dt=1e-11;                                                                   % Risoluzione temporale [sec]
Tc = 20e-9;                                                                 % Durata chip T_c [sec]
Nsamples_chip = round(Tc/dt);                                               % Campioni per chip
Nc = 32;                                                                    % Lunghezza codice (number of chips)
Nr = 8;                                                                     % Numero di simboli/bit di informazione
Ntag=1;                                                                     % Numero di tag
Tp = 1e-9;                                                                  % durata impulso [s]
Np = round(Tp/dt);                                                          % campioni impulso
A = [1/10 1/20];                                                            % Ampiezze normalizzate --> coefficienti adimensionali che modellano l'attenuazione del segnale dei diversi tag
SNRdB = 15;                                                                 % SNR desiderato in dB
beta = 0.6;                                                                 % fattore di roll-off
fc = 4e9;                                                                   % frequenza centrale
%% ============================================================
% INIZIALIZZAZIONI
%% ============================================================
c_tag=zeros(Ntag,  Nsamples_chip*Nc*Nr);                                    % codice del tag (bit di informazione + codice)
tag_bits=zeros(Ntag,  Nr);                                                  % bit di informazione (1x Nr)
code_tag=zeros(Ntag,  Nc);                                                  % codice del tag (1x Nc)
%% ============================================================
% TAG
%% ============================================================
for k=1:Ntag
    % Sistema SINCRONO - codici ortogonali
    % TO DO: generare codici Hadamard per tag
    code_tag(k,:) = Hadamard(k, Nc);                                                      % sequenza di 0 e +1
    %% ============================================================
    % GENERAZIONE DATI DEI TAG
    %% ============================================================
    % TO DO: generare bit di informazione (usare randi)
    tag_bits(k,:) = randi([0, 1], 1, Nr);                                                     % generazione dati tag k
    % TODO: conversione bipolare {-1, 1}
    tag_bip = 2*tag_bits(k, :) - 1;                                                            % Tag 1: conversione {0,1} -> {-1,+1}
    fprintf('Tag vero: %s\n', num2str(tag_bip));
    % TO DO: spreading : moltiplicazione dell'ID del tag con il suo codice
    tag = [];
    for r=1:Nr
        tag = [tag code_tag(k, :)*tag_bip(k, r)];                                                    % moltiplicazione dell'ID del tag con il suo codice
    end
    c_tag(k,:) = repelem(tag,Nsamples_chip);                                % ricorda: 1 chip "dura" Nsamples_chip
end

%% ============================================================
% READER
%% ============================================================
% Codice reader
readerCode = ones(1,Nc);                                                    % codice del reader: supponiamo siano tutti uni
readerChips = repmat(readerCode,1,Nr);                                      % sequenza ripetuta per Nr simboli
readerUp = upsample(readerChips,Nsamples_chip); % Nsamples_chip=20

% Segnale in trasmissione
% TX Root Raised Cosine
t = linspace(-Tp/2, Tp/2, Np);                                             % asse temporale locale
% TODO: generazione impulso RRC (usare la funzione fornita)
pulse=rrcp(t, Tp, beta, fc);                                                                  % creazione dell'impulso rrc
pulse = pulse / norm(pulse);                                               % normalizzazione

figure(Theme="light")
t = 0:dt:length(pulse)*dt - dt;
plot(t, pulse);
title("Impulso in trasmissione");
xlabel("Time [s]");
ylabel("Amplitude [V]");


% TO DO: creare la sequenza di impulsi in trasmissione facendo la
% convoluzione tra readerUp e pulse
tx_full = conv(readerUp, pulse);                                                              % sequenza impulsi trasmessi
delay_tx = 0; % floor((length(pulse)-1)/2);                                     
tx = tx_full(delay_tx+1 : delay_tx+length(readerUp));
tx = tx / rms(tx);                                                         % normalizzazione della potenza in [V^2] del segnale trasmesso

figure(Theme="light")
t = 0:dt:10*Nsamples_chip*dt - dt;
plot(t, tx(1:10*Nsamples_chip));
title("Segnale in trasmissione (primi 10 chip)");
xlabel("Time [s]");
ylabel("Amplitude [V]");

%% ============================================================
% SEGNALE RICEVUTO
%% ============================================================
backscatter=zeros(Ntag,  Nsamples_chip*Nc*Nr);                              % segnale di backscatter per ogni tag e di lunghezza pari a Nsamples_chip*Nc*Nr
for k=1:Ntag
    % TO DO: modulazione backscatter: moltiplicare il segnale in
    % tramissione per il codice del tag e il fattore di scala
    backscatter(k,:) = tx.*c_tag(k, :)*A(k);                                                 % Il segnale ricevuto dal tag "k" ha ampiezza A(k)
end
% TO DO: somma dei contributi dei tag
rx_signal = sum(backscatter, 1);                                             % il segnale ricevuto in assenza di rumore è la somma per ogni tag
Pr_chip=(1/Tc)*sum(rx_signal(:,1:Nsamples_chip).^2)*dt;                     % potenza media del segnale in un chip [V^2]
Pr_chip_check=mean(rx_signal(:,1:Nsamples_chip).^2);                        % check per potenza media del segnale in un chip
Pn = Pr_chip*Nc / (10^(SNRdB/10));                                          % potenza rumore in [V^2]

% TO DO: generazione del rumore
noise = randn(1, length(backscatter))*sqrt(Pn);                                      % generazione rumore AWGN in Volt
% TO DO: generazione del segnale ricevuto
rx = rx_signal + noise;                                                              % segnale ricevuto totale

figure(Theme="light")
t = 0:dt:10*Nsamples_chip*dt - dt;
plot(t, rx(1:10*Nsamples_chip));
title("Segnale in ricezione (primi 10 chip)");
xlabel("Time [s]");
ylabel("Amplitude [V]");

%% ============================================================
% RICEVITORE
%% ============================================================
%% ============================================================
% 1) MATCHED FILTER (chip-by-chip)
%% ============================================================
% preparo il pulse alla lunghezza del chip
pulse_chip = zeros(1, Nsamples_chip);
start = 0; % floor((length(pulse))/2);
pulse_chip(start+1:start+length(pulse)) = pulse;
Nchips_tot = Nc * Nr;

L_conv = 2*Nsamples_chip-1;                                                 % lunghezza vettore dopo convoluzione
v_matrix=zeros(Nchips_tot,L_conv);                                          % inizializzazione uscita matched filter
for m = 1:Nchips_tot
    idx_start = (m-1)*Nsamples_chip + 1;
    idx_end   = idx_start + Nsamples_chip - 1;
    rx_chip = rx(idx_start:idx_end);                                        % si isola un singolo chip in ricezione
    % TODO: filtro adattato
    v_matrix(m,:) = conv(rx_chip, pulse_chip);                                                      % convoluzione con template
end


t = 0:dt:dt*3*length(v_matrix(1, :)) - dt;
figure(Theme="light")
hold on
plot(t, [v_matrix(1, :) v_matrix(2, :) v_matrix(3, :)]);
title("Primi tre chip");
xlabel("Tempo [s]");
ylabel("Ampiezza [V]");

% subplot(3,1,1);
% plot(t, v_matrix(1, :));
% title("Primo chip");
% xlabel("Tempo [s]");
% ylabel("Ampiezza [V]");
% 
% subplot(3,1,2);
% plot(t, v_matrix(1, :));
% title("Secondo chip");
% xlabel("Tempo [s]");
% ylabel("Ampiezza [V]");
% 
% subplot(3,1,3);
% plot(t, v_matrix(1, :));
% title("Terzo chip");
% xlabel("Tempo [s]");
% ylabel("Ampiezza [V]");

% TO DO: Campionamento
[~, tau_0] = max(abs(v_matrix(1, :)));
v = v_matrix(:,tau_0).';
zeropad_tau = zeros(1, tau_0-1);
zeropad = zeros(1,length(v_matrix(1,:)) - 1);
zeropadlast = zeros(1, length(v_matrix(1,:))-tau_0);
plot(t, [zeropad_tau v(1) zeropad v(2) zeropad v(3) zeropadlast]);
legend(["Uscita MF", "Uscita MF campionata"]);

hold off

% 3) DESPREADING (correlatore)
est = zeros(Ntag,Nr);
for b=1:Nr
    idx = (b-1)*Nc + (1:Nc);
    y = v(idx);
    % Correlazione con il codice per recuperare l'informazione contenuta nei tag
    for k=1:Ntag
        % TO DO: correlazione: moltiplicare il segnale y con il codice del
        % tag e sommare
        est(k,b) = sum(y.*code_tag(k, :));
    end
end



% 4) DECISIONE
% Per ogni bit, la soglia viene posta a 0:
% - Se la correlazione è positiva: bit = 1
% - Se negativa: bit = 0
bits = zeros(Ntag,Nr);
for k=1:Ntag
    % TODO: decisione (sign)
    bits(k,:) = sign(est(k, :)) > 0;
end

figure(Theme="light")
subplot(2,1,1);
stem(est(1, :));
title("Ingresso decisore");
xlabel("# symbol")
ylabel("Correlation");

subplot(2,1,2);
stem(bits(1,:));
title("Uscita decisore");
xlabel("# bit");
ylabel("Bit value");