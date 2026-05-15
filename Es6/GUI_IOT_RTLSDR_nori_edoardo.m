function GUI_IOT_RTLSDR_nori_edoardo()
    clc; close all;

    %% Parametri RTL-SDR e inizializzazione
    rtlsdr_id         = '0';        
    rtlsdr_tunerfreq  = 433.882e6;  
    rtlsdr_gain       = 32.8;       
    rtlsdr_fs         = 300e3;
    rtlsdr_frmlen     = 256*1024;   
    rtlsdr_datatype   = 'single';   
    rtlsdr_ppm        = 0;          
    M = 5;

    %% === RTL-SDR ===
    obj_rtlsdr = comm.SDRRTLReceiver( rtlsdr_id,...
        'CenterFrequency', rtlsdr_tunerfreq,...
        'EnableTunerAGC', false,...
        'TunerGain', rtlsdr_gain,...
        'SampleRate', rtlsdr_fs, ...
        'SamplesPerFrame', rtlsdr_frmlen,...
        'OutputDataType', rtlsdr_datatype ,...
        'FrequencyCorrection', rtlsdr_ppm );

    %% === GUI ===
    % Creare una figura MATLAB per la dashboard.
    % La figura deve:
    % - avere un titolo, es. 'Monitor Sensori IoT'
    % - avere sfondo bianco
    % - avere dimensioni circa [100 100 1200 700]
    % - opzionale: usare la callback CloseRequestFcn per chiudere correttamente timer e SDR
    %
    % Salvare la figura nella variabile:
    %   fig
    fig = uifigure('Name', 'Monitor Sensori IoT', 'Position', [100 100 1200 700]);
    fig.CloseRequestFcn = @closeApp;
    fig.Theme = "light";

    gl = uigridlayout(fig, [2, 2]);
    gl.BackgroundColor = 'w';
    gl.Padding = [20 20 20 20];
    gl.RowSpacing = 20;
    gl.ColumnSpacing = 20;

    %% === Assi grafici ===
    % La GUI deve essere composta da 4 sotto-finestre per la visualizzazione
    % della temperatura, umidità, pressione e per lo stato della batteria
    % A tal fine, si creino tre subplot e una tabella:
    %   axT -> subplot(2,2,1) per la temperatura
    %   axH -> subplot(2,2,2) per l'umidita'
    %   axP -> subplot(2,2,3) per la pressione
    %
    % Per ciascun asse:
    % - impostare il titolo, attivare la griglia
    % axT = subplot(2, 2, 1, 'Parent', fig, "Color", "w");
    axT = uiaxes('Parent', gl, 'BackgroundColor', 'w');
    title(axT, "Temperatura", 'Color', 'k');
    axT.XColor = 'k';
    axT.YColor = 'k';
    grid(axT, 'on');

    axH = uiaxes('Parent', gl, 'BackgroundColor', 'w');
    title(axH, "Umidità", 'Color', 'k');
    axH.XColor = 'k';
    axH.YColor = 'k';
    grid(axH, 'on');

    axP = uiaxes('Parent', gl, 'BackgroundColor', 'w');
    title(axP, "Pressione", 'Color', 'k');
    axP.XColor = 'k';
    axP.YColor = 'k';
    grid(axP, 'on');

    %% === Zona tabella batterie ===
    % Creare il quarto subplot e usarlo solo per ricavarne la posizione.
    % Poi:
    % 1) nascondere l'asse
    % 2) creare un pannello con titolo 'Stato Batterie', usare il comando
    % uipanel
    % 3) creare una uitable dentro il pannello, usare il comando uitable
    %
    % La tabella deve avere due colonne:
    %   {'ID','Volt'}
    panel = uipanel('Parent', gl, 'Title', 'Stato Batterie', 'FontSize', 12, 'BackgroundColor', 'white', 'ForegroundColor', 'k');

    gl_panel = uigridlayout(panel, [1, 1]);
    gl_panel.BackgroundColor = 'w';
    gl_panel.Padding = [10 10 10 10];
    
    % uit = uitable('Parent', panel, 'ColumnName', {'ID', 'Volt'}, 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9]);
    uit = uitable('Parent', gl_panel, 'ColumnName', {'ID', 'Volt'}, 'BackgroundColor', [1 1 1; 1 1 1]); % Righe tutte bianche

    %% === STORAGE DATI ===
    % Creare quattro containers.Map per memorizzare i dati nel tempo:
    %   T_data -> temperatura
    %   H_data -> umidita'
    %   P_data -> pressione
    %   B_data -> batteria
    %
    % Usare come input:
    %   'KeyType','int32'
    %   'ValueType','any'
    T_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    H_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    P_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    B_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');

    %% === Colori sensori ===
    % Definire una matrice colors per i colori dei sensori, da poter richiamare
    % nei plot
    colors = ['k', 'r', 'g', 'b', 'y', 'c'];

    %% === TIMER REAL-TIME ===
    % Creare un timer MATLAB che:
    % - usi ExecutionMode = 'fixedSpacing'
    % - abbia Period = 1
    % - usi BusyMode = 'drop'
    % - richiami la funzione updateGUI
    %
    % Salvare il timer nella variabile:
    %   t
    %
    % Poi avviare il timer con start(t)
    t = timer('ExecutionMode', 'fixedSpacing', 'Period', 1, 'BusyMode', 'drop', 'TimerFcn', @updateGUI);
    start(t);

    %% === CALLBACK UPDATE ===
    function updateGUI(~, ~)
        %% === ACQUISIZIONE ===
        % 1) acquisire un frame dalla SDR con step(...)
        % 2) trasporre il vettore ricevuto
        % 3) fare downsample del segnale con fattore M
        %
        % Variabili richieste:
        %   Ir
        %   IrM

        Ir = step(obj_rtlsdr)';
        % struttura = load("samplesIQpacket.mat");
        % Ir = struttura.Ir;
        
        IrM = downsample(Ir, M);
        
        %% === PROCESSING ===
        % Chiamare la funzione process_frame per elaborare il frame acquisito.
        % La funzione deve restituire una struct data con campi:
        %   data.ID
        %   data.T
        %   data.H
        %   data.P
        %   data.B
        %
        % Suggerimento:
        %   data = process_frame(IrM, rtlsdr_fs);

        data = process_frame_nori_edoardo(IrM, rtlsdr_fs);

        %% === CONTROLLO DATI ===
        % Se data e' vuoto, uscire dalla callback senza aggiornare la GUI.

        if isempty(data) || ~isfield(data, 'ID')
            return;
        end
        
        % Estrarre l'ID del sensore nella variabile:
        %   ID
        ID = int32(data.ID);
        
        %% === SALVATAGGIO TEMPORANEO ===
        % Aggiornare le quattro mappe T_data, H_data, P_data, B_data.
        %
        % Per T, H e P:
        % - se la chiave ID non esiste ancora, inizializzarla col primo valore
        % - altrimenti concatenare il nuovo dato al vettore esistente
        %
        % Per B:
        % - salvare semplicemente l'ultimo valore ricevuto
        %
        % Usare:
        %   isempty(...) --> per verificare se era già stato letto un
        %   valore di quel tipo
        %   isKey(...) -->  per verificare se era già stato letto un
        %   valore per quel sensore
        %
        % Completare qui sotto i blocchi per:
        % - temperatura
        % - umidita'
        % - pressione
        % - batteria

        if ~isKey(T_data, ID) || isempty(T_data(ID))
            T_data(ID) = double(data.T);
        else
            T_data(ID) = [T_data(ID), double(data.T)];
        end
        
        if ~isKey(H_data, ID) || isempty(H_data(ID))
            H_data(ID) = double(data.H);
        else
            H_data(ID) = [H_data(ID), double(data.H)];
        end
        
        if ~isKey(P_data, ID) || isempty(P_data(ID))
            P_data(ID) = double(data.P);
        else
            P_data(ID) = [P_data(ID), double(data.P)];
        end
        
        B_data(ID) = double(data.B);
        
        %% === PARAMETRO ASSE X ===
        % Impostare STEP = X sec, esempio 5.
        % Questo valore servira' per far crescere l'asse X a blocchi di X s.
        STEP = 5;
        
        % Plotting 
        % Si è usata una funzione per ridurre l'overhead dovuto alla
        % ricopiatura delle stesse istruzioni per axT, axH, axP.
        updatePlot(axT, T_data, 'Temperatura (°C)', [10 35], STEP);
        updatePlot(axH, H_data, 'Umidità (%)', [10 90], STEP);
        updatePlot(axP, P_data, 'Pressione (Pa)', [100600 102000], STEP);
        
        %% === TABELLA BATTERIE ===
        % Creare una cell array chiamata batt contenente due colonne:
        %   {ID, Volt}
        %
        % Scorrere le chiavi di B_data e aggiornare la tabella:
        %   set(uit,'Data',batt);
        ids = keys(B_data);
        batt_cell = cell(length(ids), 2);
        for i = 1:length(ids)
            curr_id = ids{i};
            batt_cell{i, 1} = double(curr_id);
            batt_cell{i, 2} = double(B_data(curr_id));
        end
        uit.Data = batt_cell;
    end

    function updatePlot(ax, map, labY, y_lim, STEP)
        % Aggiorna il grafico passato come ax con il valore in map
        % corrispondente alla chiave. Imposta la label e il limite su y,
        % poichè per x è uguale per i 3 grafici. STEP viene passato uguale
        % per tutti come incremento del tempo (asse x).
        cla(ax);
        hold(ax, 'on');
        ks = keys(map);
        labels = {};
        maxL = 0;
        
        for i = 1:length(ks)
            k = ks{i};
            valori = map(k);
            maxL = max(maxL, length(valori));
            
            c_idx = mod(i-1, length(colors)) + 1;
            
            x_vals = 1:length(valori);
            plot(ax, x_vals, double(valori), 'Color', colors(c_idx), 'LineWidth', 1.5);
            
            labels{end+1} = sprintf('ID %d', double(k));
        end
        
        ylabel(ax, labY); xlabel(ax, 'Tempo [s]');
        ylim(ax, y_lim);
        
        if maxL > 0
            xlim(ax, [0, ceil(maxL/STEP)*STEP]);
        end
        
        if ~isempty(labels)
            legend(ax, labels, 'Location', 'northeast');
        end
        grid(ax, 'on');
    end

    %% === CHIUSURA APPLICAZIONE ===
    function closeApp(~, ~)
        % Completare questa funzione in modo che:
        % 1) fermi il timer
        % 2) cancelli il timer
        % 3) rilasci la SDR
        % 4) chiuda la figura
        %
        % Usare blocchi try/catch per evitare errori in chiusura.
        %
        % Suggerimento:
        %   stop(t)
        %   delete(t)
        %   release(obj_rtlsdr)
        %   delete(gcf)
        fprintf('Chiusura in corso...\n');
        try stop(t); catch; end
        try delete(t); catch; end
        try release(obj_rtlsdr); catch; end
        try delete(fig); catch; end
    end
end