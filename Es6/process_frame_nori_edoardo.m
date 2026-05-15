function data = process_frame_nori_edoardo(IrM, rtlsdr_fs)

% process_frame_template
%
% Scopo:
% Elaborare un frame acquisito dalla SDR e restituire i dati del sensore:
%   - ID
%   - Temperatura
%   - Umidità
%   - Pressione
%   - Batteria
%
% Output:
%   data → struttura con campi:
%       data.ID
%       data.T
%       data.H
%       data.P
%       data.B
%
% Se nessun pacchetto valido viene trovato:
%   data = []

data = [];

%% === PARAMETRI DI RICEZIONE ===
%% Parametri di ricezione
thcorr = 13;            % Soglia per la detection del pacchetto (idealmente 13)
rb = 2500;                              % bit rate in bit/s         ‾\
barker13 = [1 0 1 0 1 1 0 0 1 1 1 1 1]; % Sequenza di Barker          |-> dal TX
gx = gf( [1 1 1 0 0 1 1 1 1] );         % Pol. generatore del CRC-8 _/
M = 5;                 % Fattore riduzione fs


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


%% PER I PUNTI A-B-C-D-E usare il codice sviluppato per l'Esercitazione 5

%% === A) DEMODULAZIONE ===
% Implementare energy detector:
A = filter(b_dem, 1, abs(IrM).^2);
t = 0:1/rb:size(IrM, 2)/rb - 1/rb;

%% === B) SINCRONISMO DI SIMBOLO ===
A2 = A.^2;
timew = filter( biir, aiir, A2 );
n = rtlsdr_fs / ( M * rb );
pimez = round( n/4 );
timewave = [ zeros( 1, pimez ) timew( 1:end-pimez ) ];
synchwave = sign( timewave );

%% === C) CAMPIONAMENTO ===
% Usare la funzione campionamento
[softbits, sampinst] = campionatore(A,synchwave);

%% === D) DECISIONE ===
% Convertire softbits in bit
% E = max(abs(IrM))^2/(2*rb/5)*10^(rtlsdr_gain/10); % 
decoded = softbits > 0;

%% === E) SINCRONISMO DI PACCHETTO ===
decoded_mapped = mapper(decoded, 1);
yn = filter(barker13_flip, 1, decoded_mapped);
packsynch = yn;

%% === F) ESTRAZIONE PAYLOAD ===
T_lenD = 14;
H_lenD = 10;
P_lenD = 16;
B_lenD = 10;
datalen = T_lenD + H_lenD + P_lenD + B_lenD + 4 + 4 + 8; %lunghezza totale del payload
for j = 1 : length(decoded)-datalen % Cerca un punto j dove la correlazione packsynch supera la
    % soglia thcorr → inizio pacchetto rilevato.
    if packsynch(j) >= thcorr       %thcorr = 13
        payload = decoded(j+1:j+datalen); % è il pacchetto senza preambolo
        ID = bin2dec( num2str( payload( 1:4 ) ) );%serve per convertire i primi 4 bit del pacchetto (payload)
        % in un numero decimale, che rappresenta l'ID del sensore
        %num2str(payload(1:4)) converte un vettore in una stringa

        cur = 9;
        T=[]; H=[]; P=[]; B=[];
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
        [ quoziente, remainder ] = deconv( payloadGF2, gx ); %Si calcola il resto della divisione polinomiale in GF(2)
        %con il polinomio generatore gx.
        if remainder == 0
            % if bin2dec( num2str( payload(5:8) ) ) == 0
            %     fprintf( 'Sensore %d: TEST OK\n', ID )
            % else
            %     fprintf( 'Sensore %d: %s%s%s%s\n', ID, str_T, str_H, str_P, str_B )
            % end
            %% NEW
            data.ID = ID;
            data.T = T;
            data.H = H;
            data.P = P;
            data.B = B;
            return;
        else
            % fprintf( 2, 'Errore ID %d\n', ID )
            % fprintf( 2, 'Errore ID %d: %s%s%s%s\n', ID, str_T, str_H, str_P, str_B )
            return;
        end
    end
end
end