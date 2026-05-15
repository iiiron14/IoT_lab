%% Radio FM real time con RTL-SDR
% Il codice riproduce la radio FM alla frequenza rtlsdr_tunerfreq, senza
% salvare alcun file sul computer. Per riprodurre direttamente l'audio si
% usa la funzione soundsc().
% La riproduzione pare continua ma in realtà c'è uno stacco tra i vari
% "pacchetti" che vengono elaborati singolarmente. Il pacchetto successivo
% viene ricevuto ed elaborato durante la riproduzione del precedente.
% Aumentare i dati che vengono elaborati in un ciclo (tramite un buffer)
% porta ad un aumento della latenza, ma riduce la frequenza degli stacchi.
% La percezione di tali interruzioni dipende soprattutto dalle prestazioni
% del computer.
close all
clear
clc


%% INPUT
tempo = 50;     % Durata in secondi
%rtlsdr_tunerfreq = 92.8e6;    % Radio Studio Delta
rtlsdr_tunerfreq = 94.9e6;    % Radio Bruno
%rtlsdr_tunerfreq  = 100.8e6;  % Radio Sabbia



%% RTL-SDR PARAMETERS RADIO FM
% rtlsdr_tunerfreq  =           % RTL-SDR tuner frequency in Hz
rtlsdr_id         = '0';        % RTL-SDR ID
rtlsdr_gain       = 32.8;       % RTL-SDR tuner gain in dB
rtlsdr_fs         = 916000;     % RTL-SDR sampling rate in Hz (maggiore della banda base = 180 kHz)
rtlsdr_frmlen     = 256*1024;   % RTL-SDR output data frame size (multiple of 256) (dim quasi massime)
rtlsdr_datatype   = 'single';   % RTL-SDR output data type
rtlsdr_ppm        = 0;          % RTL-SDR tuner parts per million correction


%% SYSTEM OBJECTS
obj_rtlsdr = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency', rtlsdr_tunerfreq,...
    'EnableTunerAGC', false,...
    'TunerGain', rtlsdr_gain,...
    'SampleRate', rtlsdr_fs, ...
    'SamplesPerFrame', rtlsdr_frmlen,...
    'OutputDataType', rtlsdr_datatype ,...
    'FrequencyCorrection', rtlsdr_ppm );


%% ALTRI DATI
sim_buffer = 10;
sim_loops = round( tempo * rtlsdr_fs / rtlsdr_frmlen / sim_buffer );
audio_fs = 44100;       % Deve essere compatibile con il PC
rp_a = 1;               % Passband ripple in dB    ‾\
rs_a = 30;              % Stopband attenuation in dB \
f_a  = [ 90e3 110e3 ];  % Cutoff frequencies         /
a_a  = [ 1 0 ];         % Desired amplitudes       _/
dev_a= [(10^(rp_a/20)-1)/(10^(rp_a/20)+1) 10^(-rs_a/20)];
[n_a,fo_a,ao_a,w_a] = firpmord(f_a,a_a,dev_a,rtlsdr_fs);
b_emittente = firpm(n_a,fo_a,ao_a,w_a);
rp_b = 1;               % Passband ripple in dB    ‾\
rs_b = 30;              % Stopband attenuation in dB \
f_b  = [ 15e3 18e3 ];   % Cutoff frequencies         /
a_b  = [ 1 0 ];         % Desired amplitudes       _/
dev_b= [(10^(rp_b/20)-1)/(10^(rp_b/20)+1) 10^(-rs_b/20)];
[n_b,fo_b,ao_b,w_b] = firpmord(f_b,a_b,dev_b,rtlsdr_fs);
b_mono = firpm(n_b,fo_b,ao_b,w_b);
T = 1/rtlsdr_fs;
delta_f_max = 75e3;

%% LOOP
for cur = 1 : sim_loops
    if rem( cur-1, 5 ) == 0
        fprintf('%d / %d s\n', round((cur-1)*sim_buffer*rtlsdr_frmlen/rtlsdr_fs), tempo );
    end
    
    % Catturo un pacchetto
    run_time = 0;
    buffer_len = sim_buffer * rtlsdr_frmlen;
    buffer = zeros( 1, buffer_len );
    while run_time < sim_buffer
        rtlsdr_data = step(obj_rtlsdr);
        buffer( run_time*rtlsdr_frmlen+1 : (run_time+1)*rtlsdr_frmlen ) = rtlsdr_data';
        run_time = run_time + 1;
    end

    % Filtraggio per ricavare dallo spettro l'emittente selezionata [COMPLETARE]
    Ir_PB = filter(b_emittente,1,buffer);
    Ir_PB = Ir_PB';
    
    % Demodulazione FM [COMPLETARE]
    kf = delta_f_max/(max(abs(Ir_PB)));

    xdem = angle(Ir_PB(2:end,1).*(conj(Ir_PB(1:end-1,1)))) / (2*pi*kf*T);
    
    % Filtrare l'equivalente mono [COMPLETARE]
    xdem_mono = filter(b_mono,1,xdem);

    % Rifiniture audio
    y = resample( xdem_mono, audio_fs, rtlsdr_fs );
    y = 0.8 * y/max(abs(y)); % automatico per 'soundsc'

    % Riproduzione
    soundsc( y, audio_fs );

end


%% COME RIPRODURRE AUDIO DIRETTAMENTE DA MATLAB:
% 'playblocking()' prosegue con il codice solo a fine audio.
% 'play()' esegue ma non fa nulla se il play precedente non è già finito
% 'audioplayer()' crea l'oggetto da riprodurre, non può essere modificato
%   fino alla fine della sua riproduzione altrimenti si interrompe.
% 'pause()' blocca il codice per il tempo specificato [s]
% 'pause' attende un click oppure input da tastiera per proseguire
% 'isplaying()' riceve oggetto e dice se sta suonando