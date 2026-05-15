function equalizerGUI
    fig = uifigure('Name', 'SDR FM Equalizer', 'Position', [100 100 450 400]);
    
    % Inizializzazione dati
    appData = struct();
    appData.values = ones(1, 6) * 0.5;
    appData.keepRunning = true;
    setappdata(fig, 'appData', appData);
    
    % Creazione Slider (come prima)
    numSliders = 6;
    labels = gobjects(numSliders, 1);
    for i = 1:numSliders
        uilabel(fig, 'Position', [20, 345 - (i - 1) * 40, 80, 22], 'Text', ['Band ' num2str(i)]);
        s = uislider(fig, 'Position', [100, 350 - (i - 1) * 40, 200, 3]);
        s.Limits = [0 1]; s.Value = 0.5;
        labels(i) = uilabel(fig, 'Position', [310, 345 - (i - 1) * 40, 50, 22], 'Text', '0.50');
        s.ValueChangedFcn = @(src, event) updateValue(i, src, labels, fig);
    end
    uilabel(fig, 'Position', [310, 60, 100, 22], 'Text', 'Frequenza (MHz):');
    freqField = uieditfield(fig, 'numeric', 'Position', [310, 35, 80, 25]);
    freqField.Value = 94.9; % Valore di default (Radio Bruno)
    
    % Salviamo il riferimento nei dati della app
    appData.freqField = freqField;
    setappdata(fig, 'appData', appData);
    
    % Bottone Start SDR
    uibutton(fig, 'Text', 'Start Radio', 'Position', [175, 20, 100, 30], ...
        'ButtonPushedFcn', @(btn, event) startSDRProcessing(fig));
    
    % Callback per chiusura pulita
    fig.CloseRequestFcn = @(src, event) deleteFig(fig);
end

function updateValue(index, slider, labels, fig)
    appData = getappdata(fig, 'appData');
    appData.values(index) = slider.Value;
    labels(index).Text = sprintf('%.2f', slider.Value);
    setappdata(fig, 'appData', appData);
end

function deleteFig(fig)
    appData = getappdata(fig, 'appData');
    appData.keepRunning = false;
    setappdata(fig, 'appData', appData);
    delete(fig);
end

function startSDRProcessing(fig)
    %% Configurazione SDR (Parametri dal tuo script)
    % rtlsdr_tunerfreq = 94.6e6;  % non usato per il tuning di frequenza
    rtlsdr_fs = 916000;
    % rtlsdr_frmlen = 256*1024; % non buona per equalizzazione in real time
    rtlsdr_frmlen = 128*1024;
    audio_fs = 44100;
    % sim_buffer = 10; % in questa situazione non è necessario
    delta_f_max = 75e3;
    T = 1/rtlsdr_fs;

    % Oggetti di sistema
    appData = getappdata(fig, 'appData');
    freqField = appData.freqField;

    currentFreq = freqField.Value*1e6;
    obj_rtlsdr = comm.SDRRTLReceiver('CenterFrequency', currentFreq, ...
        'SampleRate', rtlsdr_fs, 'SamplesPerFrame', rtlsdr_frmlen);
    
    writer = audioDeviceWriter('SampleRate', audio_fs);
    
    % Filtri (Creati una sola volta per efficienza)
    [n_a,fo_a,ao_a,w_a] = firpmord([90e3 110e3], [1 0], [0.05 0.01], rtlsdr_fs);
    b_emittente = firpm(n_a,fo_a,ao_a,w_a);
    [n_b,fo_b,ao_b,w_b] = firpmord([15e3 18e3], [1 0], [0.05 0.01], rtlsdr_fs);
    b_mono = firpm(n_b,fo_b,ao_b,w_b);

    % Stato equalizzatore
    last_199_frames = zeros(199, 1);
    zi_emittente = zeros(max(size(b_emittente))-1, 1);
    zi_mono = zeros(max(size(b_mono))-1, 1);

    fprintf('Radio in riproduzione...\n');
    obj_rtlsdr.SamplesPerFrame = rtlsdr_frmlen;
    
    while true
        drawnow limitrate;
        if ~isvalid(fig), break; end

        % frequency check
        newFreq = freqField.Value*1e6;
        if newFreq ~= currentFreq
            obj_rtlsdr.CenterFrequency = newFreq;
            currentFreq = newFreq;
            fprintf('Sintonizzato su %.1f MHz\n', newFreq/1e6);
        end

        % 1. Prendi UN SOLO pacchetto (Latenza minima)
        rtlsdr_data = step(obj_rtlsdr); 
        
        % 2. Demodulazione immediata
        [Ir_PB, zi_emittente] = filter(b_emittente, 1, rtlsdr_data, zi_emittente);
        kf = delta_f_max/(max(abs(Ir_PB)));
        xdem = angle(Ir_PB(2:end).*(conj(Ir_PB(1:end-1)))) / (2*pi*kf*T);
        [xdem_mono, zi_mono] = filter(b_mono, 1, xdem, zi_mono);
        
        % 3. Resample e Equalizzazione
        y = resample(xdem_mono, audio_fs, rtlsdr_fs);
        y = 0.8 * y/max(abs(y)); 
        
        appData = getappdata(fig, 'appData');
        
        y_equalized = processAudioLab(y, appData.values, audio_fs, length(y), last_199_frames);
        last_199_frames = y(end-198:end);
    
        % 4. Scrittura diretta (audioDeviceWriter gestisce internamente il buffering)
        writer(y_equalized); 
    end
    release(obj_rtlsdr);
    release(writer);
end