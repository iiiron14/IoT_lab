%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enrico Testi                                                       %
% Dip. di Ingegneria dell' Energia Elettrica e                           % 
% dell'Informazione "Guglielmo Marconi" (DEI)                            %
% Alma Mater Studiorum - Università di Bologna                           %
% March 2025                                                                %
% Laboratorio IoT              %
% Laurea in Ingegneria Elettronica per l'Energia e l'Inform. @ Cesena    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Demodulazione e decodifica pacchetti generati da sensore ambientale    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; clc;

%% Parametri di ricezione
thcorr = 13;            % Soglia per la detection del pacchetto (idealmente 13)
rb = 2500;                              % bit rate in bit/s         ‾\
barker13 = [1 0 1 0 1 1 0 0 1 1 1 1 1]; % Sequenza di Barker          |-> dal TX
gx = gf( [1 1 1 0 0 1 1 1 1] );         % Pol. generatore del CRC-8 _/
M = 5;                 % Fattore riduzione fs 
Nframes = 10000;       % Numero di frames acquisiti

%% Parametri RTL-SDR e inizializzazione
rtlsdr_id         = '0';        % RTL-SDR ID
rtlsdr_tunerfreq  = 433.882e6;  % RTL-SDR tuner frequency in Hz
% Conviene mantenere un offset per evitare una riga alla frequenza centrale...
rtlsdr_gain       = 32.8;       % RTL-SDR tuner gain in dB
% [0 0.9 1.4 2.7 3.7 7.7 8.7 12.5 14.4 15.7 16.6 19.7 20.7 22.9 25.4 28
%   29.7 32.8 33.8 36.4 37.2 38.6 40.2 42.1 43.4 43.9 44.5 48 49.6]
rtlsdr_fs         = 300e3;      % RTL-SDR sampling rate in Hz
rtlsdr_frmlen     = 256*1024;   % RTL-SDR output data frame size (multiple of 256)
rtlsdr_datatype   = 'single';   % RTL-SDR output data type
rtlsdr_ppm        = 0;          % RTL-SDR tuner parts per million correction

obj_rtlsdr = comm.SDRRTLReceiver( rtlsdr_id,...
    'CenterFrequency', rtlsdr_tunerfreq,...
    'EnableTunerAGC', false,...
    'TunerGain', rtlsdr_gain,...
    'SampleRate', rtlsdr_fs, ...
    'SamplesPerFrame', rtlsdr_frmlen,...
    'OutputDataType', rtlsdr_datatype ,...
    'FrequencyCorrection', rtlsdr_ppm );


%% Variabili da definire prima del loop
fs = rtlsdr_fs/M;   % nuova frequenza di campionamento
os = fs/rb;         % fattore di sovracampionamento = campioni per simbolo
% Pesi per FIR della demodulazione non coerente:
b_dem = [ ones(1,round(os/2)), -ones(1,round(os/2)) ];
% Pesi per FIR sincronismo:
barker13_flip = fliplr( mapper( barker13, 1 ) );

% Progettazione filtro IIR di dimensioni minime, con banda passante
% centrata al tempo di bit, di larghezza 10 Hz e ripple di 1 dB.
% Frequenza di campionamento ridotta del fattore M.
Rp = 1;         % Ripple in banda passante [dB]
bw = 10;        % Larghezza banda passante [Hz]
% Wp deve essere un vettore contenente inizio e fine della banda passante,
% con le due frequenze normalizzate a metà della freq di campionamento.
Bal = ( rb-bw/2 ) / ( fs/2 );
Bah = ( rb+bw/2 ) / ( fs/2 );
Wp = [ Bal Bah ];
[ biir, aiir ] = cheby1( 1, Rp, Wp );


%% CARICAMENTO DA FILE DI PACCHETTI CATTURATI
load('samplesIQpacket.mat'); % the vector samplesIQ will be created from the file samples

%% ACQUISITION LOOP
% Disattiviamo il loop di acquisizione dato che carichiamo il file tramite load(...) 
%for i = 1 : Nframes  
% if rem( i, 100 ) == 0
    %     fprintf('frame #%d\n', i);
    % end
% Caricamento di un frame dal dispositivo RTL-SDR
    % Ir = step(obj_rtlsdr)';

%%%%%%%%%%%%%%%%%%%%

% Downsample
    IrM = downsample(Ir,M);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % A) Demodulazione non-coerente: "IrM" e' il vettore inviluppo 
    % complesso "I(nT)", "A" e' il vettore "A(nT)"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    A = filter(b_dem, 1, abs(IrM).^2);
    t = 0:1/rb:size(IrM, 2)/rb - 1/rb;
    figure;
    plot(t, abs(IrM));
    xlabel("Time [s]");
    hold on;
    plot(t, A);
    legend("Ir", "A");
    hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % B) Estrazione della timing-wave. Il vettore synchwave 
    % rappresenta il segnale "s(nT)" 
    NFFT = 1024;
    [Pxx, freq] = pwelch(A, hanning(NFFT), [], NFFT, fs, "centered");
    figure
    plot(freq, 10*log10(Pxx));
    xlabel("Frequencies [Hz]");
    ylabel("Magnitude [dB]");
    title("PSD of demodulated signal A");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Introduco la non linearità
    A2 = A.^2;
    [Pxx2, freq2] = pwelch(A2, hanning(NFFT), [], NFFT, fs, "centered");
    figure;
    plot(freq2, 10*log10(Pxx2));
    xlabel("Frequencies [Hz]");
    ylabel("Magnitude [dB]");
    title("Signal A2=A^2 (non linearity)");
% Isolo la sinusoide a f = bit rate
    timew = filter( biir, aiir, A2 ); 
    [Pxx3, freq3] = pwelch(timew, hanning(NFFT), [], NFFT, fs, "centered");
    figure;
    plot(freq3, 10*log10(Pxx3));
    xlabel("Frequencies [Hz]");
    ylabel("Amplitude [dB]");
    title("Symbol rate isolated");

% Sfasamento di pi/2
    n = rtlsdr_fs / ( M * rb );
    pimez = round( n/4 );
    timewave = [ zeros( 1, pimez ) timew( 1:end-pimez ) ];
    synchwave = sign( timewave );
    figure;
    hold on
    plot(t, A);
    plot(t, synchwave);
    hold off;
    legend("A(nT)", "synchwave s(t)");
    xlabel("Time [s]");
    ylabel("Amplitude [V]");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARTE RESTANTE DEL PROCESSING PER ARRIVARE AI BIT
% I prossimi step li vedremo a lezione
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Campionamento al tempo di simbolo
sample = [0, diff(synchwave > 0.5)]; % individua i fronti positivi (+1) e negativi (-1)
sample_idx = find(sample == 1);      % seleziona solo i fronti positivi
A_sampled = A(sample_idx);
t_sampled = t(sample_idx);
figure;
stem(t_sampled, A_sampled);
xlabel("Time [s]");
ylabel("Samples [V]");

% Decisione tramite comparazione con soglia
% Come soglia utilizzo l'energia, si ricorda di implementare l'adattamento
% con il guadagno del dispositivo hardware
E = max(abs(IrM))^2/(2*rb/5)*10^(rtlsdr_gain/10);
bits = A_sampled > 0.6*E;
    
% Sincronismo di pacchetto

% Estrazione del payload e decodifica
 
%end