% Andrea Giorgetti 
% March 2022
% Laboratorio di Reti di Sensori per l'Energia e l'Ambiente
% Laurea in Ingegneria elettronica per l'energia e l'informazione @ Cesena
% Cattura dei campioni I e Q usando l'RTL-SDR
% April 2018, Revised May 2021, Revised March 2022
clear; close all; clc;

%% RTL-SDR PARAMETERS
rtlsdr_id         = '0';       % RTL-SDR ID
rtlsdr_tunerfreq  = 94.9e6;    % RTL-SDR tuner frequency in Hz 
rtlsdr_gain       = 32.8;      % RTL-SDR tuner gain in dB [0 0.9 1.4 2.7 3.7 7.7 8.7 12.5 14.4 15.7 16.6 19.7 20.7 22.9 25.4 28 29.7 32.8 33.8 36.4 37.2 38.6 40.2 42.1 43.4 43.9 44.5 48 49.6]
rtlsdr_fs         = 916000;    % RTL-SDR sampling rate in Hz
rtlsdr_frmlen     = 256*50;    % RTL-SDR output data frame size (multiple of 256)
rtlsdr_datatype   = 'single';  % RTL-SDR output data type
rtlsdr_ppm        = 0;         % RTL-SDR tuner parts per million correction
sim_time          = 500;       % AG: simulation time in numero di frames. Es. 100 frames ognuno di 256*200 campioni
nomefileout='samplesIQcatturati.mat'; % Output file name

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

%%% check if RTL-SDR is active
if isempty(sdrinfo(obj_rtlsdr.RadioAddress))
    error(['RTL-SDR failure. Please check connection to ',...
        'MATLAB using the "sdrinfo" command.']);
end

%% SIGNAL AQUISITION
run_time = 0;
lunghezzaout=sim_time*rtlsdr_frmlen;
samplesIQ=zeros(1,lunghezzaout); %% inizializzo un vettore vuoto
while run_time < sim_time
    fprintf('Acq. frame n.%d/%d\n',run_time+1,sim_time);
    rtlsdr_data = step(obj_rtlsdr); % fetch a frame from the rtlsdr
    samplesIQ(run_time*rtlsdr_frmlen+1:(run_time+1)*rtlsdr_frmlen)=rtlsdr_data'; 
    run_time = run_time + 1;
end

%%% PLOT DELLE VIE I e Q %%%
figure
subplot(311),plot(real(samplesIQ)),xlabel('samples'),ylabel('Ampiezze via I'),title('I e Q non filtrate');
subplot(312),plot(imag(samplesIQ)),xlabel('samples'),ylabel('Ampiezze via Q');
subplot(313),plot(abs(samplesIQ)), xlabel('samples'),ylabel('Modulo, |I+jQ|)');

%%% SALVATAGGIO dei campioni I+jQ %%%
save(nomefileout,'samplesIQ');