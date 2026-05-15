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
clear all; close all; clc;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decommentare per attivare il loop di acquisizione da chiavetta %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1 : Nframes  
    if rem( i, 100 ) == 0
        fprintf('frame #%d\n', i);
    end
% Caricamento di un frame dal dispositivo RTL-SDR
    Ir = step(obj_rtlsdr)';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Downsample
IrM = downsample(Ir,M);

%% Incollare qui il codice sviluppato all'Es4 (non servono i grafici)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % A) Demodulazione non-coerente: "IrM" e' il vettore inviluppo 
    % complesso "I(nT)", "A" e' il vettore "A(nT)"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
A = filter(b_dem, 1, abs(IrM).^2);
t = 0:1/rb:size(IrM, 2)/rb - 1/rb;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % B) Estrazione della timing-wave. Il vettore synchwave 
    % rappresenta il segnale "s(nT)" 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A2 = A.^2;

% Isolo la sinusoide a f = bit rate
timew = filter( biir, aiir, A2 ); 

% Sfasamento di pi/2
n = rtlsdr_fs / ( M * rb );
pimez = round( n/4 );
timewave = [ zeros( 1, pimez ) timew( 1:end-pimez ) ];
synchwave = sign( timewave );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARTE RESTANTE DEL PROCESSING PER ARRIVARE AI BIT (Esercitazione 5)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% C) Campionamento al tempo di simbolo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[softbits,sampinst] = campionatore(A,synchwave);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% D) Decisione tramite comparazione con soglia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Come soglia uso una parte frazionaria dell'energia del segnale. Dalla
% teoria l'ampiezza dovrebbe proprio essere E, tenendo in conto il rumore
% utilizzo 0.8*E. Questo approccio risulta particolarmente utile per i
% periodi di silenzio nei quali così non si hanno interpretazioni sbagliate
% di 1 o 0 ma solo 0.
E = max(abs(IrM))^2/(2*rb/5)*10^(rtlsdr_gain/10);
decoded = softbits > 0.8*E;
    if i <= 2 
        figure;
        hold on;
        plot(t(sampinst), softbits);
        stem(t(sampinst), decoded);
        hold off;
        title("Confronto di A(nT) e il segnale decodificato");
        xlabel("Istanti di campionamento nT");
        legend("A(nT)", "Decoded");
        grid on;

    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E) Sincronismo di pacchetto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
decoded_mapped = mapper(decoded, 1);
yn = filter(barker13_flip, 1, decoded_mapped);
packsynch = yn;

    if i <= 2
        figure;
        hold on;
        stem(t(sampinst), yn);
        stem(t(sampinst), decoded);
        plot(t(sampinst), softbits);
        hold off;
        xlabel("Istanti di campionamento");
        ylabel("Ampiezze");
        legend("yn", "decoded", "A(nT)");
        grid on;
    end

% F) Estrazione del payload e decodifica
%Inserire il numero di bit dei vari dati.
    %Si ipotizza sempre ID=4 bit, type=4 bit, crc=8 bit;
    T_lenD = 14;
    H_lenD = 10;
    P_lenD = 16;
    B_lenD = 10;
    datalen = T_lenD + H_lenD + P_lenD + B_lenD + 4 + 4 + 8;
    for j = 1 : length(decoded)-datalen
        if packsynch(j) >= thcorr
            payload = decoded(j+1:j+datalen); % è il pacchetto senza preambolo
            ID = bin2dec( num2str( payload( 1:4 ) ) );
            cur = 9;
            str_T = '';
            str_H = '';
            str_P = '';
            str_B = '';
            if( payload(5) )
                T = bin2dec( num2str( payload(cur:cur+T_lenD-1) ) );
                T = (T-4000)/100;
                cur = cur + T_lenD;
                str_T = strcat( ' Temp= ', num2str(T, '%3.2f' ), '°C;  ' );
            end
            if( payload(6) )
                H = bin2dec( num2str( payload(cur:cur+H_lenD-1) ) );
                H = H/10;
                cur = cur + H_lenD;
                str_H = strcat( ' Hum= ', num2str(H, '%3.1f' ), '%;  ' );
            end
            if( payload(7) )
                P = bin2dec( num2str( payload(cur:cur+P_lenD-1) ) );
                P = P+50000;
                cur = cur + P_lenD;
                str_P = strcat( ' Press= ', num2str(P/100, '%5.2f' ), 'hPa;  ' );
            end
            if( payload(8) )
                B = bin2dec( num2str( payload(cur:cur+B_lenD-1) ) );
                B = B*5/1023;
                cur = cur + B_lenD;
                str_B = strcat( ' Batt= ', num2str(B, '%2.2f' ), 'V;  ' );
            end
            % Controllo CRC
            payloadGF2 = gf( payload(1:cur+7) );
            [ quoziente, remainder ] = deconv( payloadGF2, gx );
            if remainder == 0
                if bin2dec( num2str( payload(5:8) ) ) == 0
                    fprintf( 'Sensore %d: TEST OK\n', ID )
                else
                    fprintf( 'Sensore %d: %s%s%s%s\n', ID, str_T, str_H, str_P, str_B )
                end
            else
                fprintf( 2, 'Errore ID %d\n', ID )
                fprintf( 2, 'Errore ID %d: %s%s%s%s\n', ID, str_T, str_H, str_P, str_B )
            end
        end
    end
end