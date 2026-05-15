function GUI_IOT_RTLSDR_facoltativo()
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
    fig = uifigure('Name', 'Monitor Sensori IoT Pro', 'Position', [50 50 1400 800], 'Color', 'w');
    fig.CloseRequestFcn = @closeApp;
    fig.Theme = "light";
    
    % Griglia principale: 1 riga, 2 colonne
    gl_main = uigridlayout(fig, [1, 2]);
    gl_main.BackgroundColor = 'w';
    gl_main.Padding = [15 15 15 15];
    gl_main.ColumnWidth = {200, '1x'}; % Colonna 1 fissa a 200px, Colonna 2 dinamica
    gl_main.RowHeight = {'1x'};
    
    %% === PANNELLO CONTROLLI  ===
    ctrl_panel = uipanel('Parent', gl_main, 'Title', 'Pannello Controlli', 'FontSize', 12, 'BackgroundColor', 'w', 'ForegroundColor', 'k');
    ctrl_panel.Layout.Row = 1;
    ctrl_panel.Layout.Column = 1;
    
    gl_ctrl = uigridlayout(ctrl_panel, [8, 1]); % Griglia verticale interna
    gl_ctrl.BackgroundColor = 'w';
    gl_ctrl.RowHeight = {'fit', 'fit', 'fit', 100, 'fit', '1x'};
    gl_ctrl.RowSpacing = 10; % Un po' di respiro tra un elemento e l'altro
    
    % Pulsante Start/Stop
    btn_startstop = uibutton(gl_ctrl, 'state', 'Text', 'STOPPED', 'BackgroundColor', [1 0.3 0.3], 'FontWeight', 'bold', 'ValueChangedFcn', @toggleTimer);
    
    % Pulsante Reset
    btn_reset = uibutton(gl_ctrl, 'Text', 'Reset Grafici', 'BackgroundColor', [0.9 0.9 0.9], 'ButtonPushedFcn', @resetData);
    
    % Menu / Lista Switch per ID Sensori
    uilabel(gl_ctrl, 'Text', 'Filtro Sensori VISIBILI:', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % Listbox
    sensor_selector = uilistbox(gl_ctrl, 'Items', {'In attesa di ID...'}, 'ItemsData', [], 'Multiselect', 'on', 'ValueChangedFcn', @(src,event) drawnow);
    
    % Statistiche
    uilabel(gl_ctrl, 'Text', '--- Statistiche Live ---', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    stats_text = uitextarea(gl_ctrl, 'Editable', 'off', 'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95]);
    
    %% === GRIGLIA GRAFICI ===
    gl_plots = uigridlayout(gl_main, [2, 2]);
    gl_plots.BackgroundColor = 'w';
    gl_plots.Layout.Row = 1;
    gl_plots.Layout.Column = 2;
    gl_plots.RowHeight = {'1x', '1x'};
    gl_plots.ColumnWidth = {'1x', '1x'};
    
    %% === Assi grafici ===
    axT = uiaxes('Parent', gl_plots, 'BackgroundColor', 'w');
    title(axT, "Temperatura", 'Color', 'k'); axT.XColor = 'k'; axT.YColor = 'k'; grid(axT, 'on');
    
    axH = uiaxes('Parent', gl_plots, 'BackgroundColor', 'w');
    title(axH, "Umidità", 'Color', 'k'); axH.XColor = 'k'; axH.YColor = 'k'; grid(axH, 'on');
    
    axP = uiaxes('Parent', gl_plots, 'BackgroundColor', 'w');
    title(axP, "Pressione", 'Color', 'k'); axP.XColor = 'k'; axP.YColor = 'k'; grid(axP, 'on');
    
    %% === Zona tabella batterie ===
    panel = uipanel('Parent', gl_plots, 'Title', 'Stato Batterie (Decrescente)', 'FontSize', 12, 'BackgroundColor', 'white', 'ForegroundColor', 'k');
    gl_panel = uigridlayout(panel, [1, 1]);
    gl_panel.BackgroundColor = 'w';
    gl_panel.Padding = [10 10 10 10];
    
    uit = uitable('Parent', gl_panel, 'ColumnName', {'ID', 'Volt'}, 'BackgroundColor', [1 1 1; 1 1 1]); 
    
    %% === STORAGE DATI ===
    T_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    H_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    P_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    B_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    
    colors = ['k', 'r', 'g', 'b', 'y', 'c'];
    
    %% === TIMER REAL-TIME ===
    t = timer('ExecutionMode', 'fixedSpacing', 'Period', 1, 'BusyMode', 'drop', 'TimerFcn', @updateGUI);
    
    % Funzione per accendere/spegnere il timer
    function toggleTimer(src, ~)
        if src.Value == 1
            src.Text = 'RUNNING';
            src.BackgroundColor = [0.3 1 0.3]; % Verde
            start(t);
        else
            src.Text = 'STOPPED';
            src.BackgroundColor = [1 0.3 0.3]; % Rosso
            stop(t);
        end
    end
    
    % Funzione per resettare i grafici
    function resetData(~, ~)
        T_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        H_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        P_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        B_data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        sensor_selector.Items = {'In attesa di ID...'};
        sensor_selector.ItemsData = [];
        uit.Data = [];
        stats_text.Value = '';
        cla(axT);
        cla(axH);
        cla(axP);
    end

    %% === CALLBACK UPDATE ===
    function updateGUI(~, ~)
        % Acquisizione
        %Ir = step(obj_rtlsdr)';
        struttura = load("samplesIQpacket.mat");
        Ir = struttura.Ir;

        IrM = downsample(Ir, M);
        data = process_frame_nori_edoardo(IrM, rtlsdr_fs);
        
        if isempty(data) || ~isfield(data, 'ID')
            return;
        end
        
        ID = int32(data.ID);
        
        % === SISTEMA RICONOSCIMENTO OUTLIER ===
        if any(data.T < -40) || any(data.T > 80), return; end
        if any(data.H < 0) || any(data.H > 100), return; end
        if any(data.P < 80000) || any(data.P > 120000), return; end
        
        % Aggiornamento Lista Sensori
        current_ids = sensor_selector.ItemsData;
        if ~ismember(ID, current_ids)
            if isempty(current_ids)
                sensor_selector.Items = {sprintf('Sensore %d', ID)};
                sensor_selector.ItemsData = [ID];
                sensor_selector.Value = ID; % Selezionato di default
            else
                sensor_selector.Items{end+1} = sprintf('Sensore %d', ID);
                sensor_selector.ItemsData(end+1) = ID;
                % Mantieni selezionati anche i precedenti più il nuovo
                sensor_selector.Value = [sensor_selector.Value, ID];
            end
        end
        
        % Salvataggio Temporaneo
        if ~isKey(T_data, ID), T_data(ID) = double(data.T); else, T_data(ID) = [T_data(ID), double(data.T)]; end
        if ~isKey(H_data, ID), H_data(ID) = double(data.H); else, H_data(ID) = [H_data(ID), double(data.H)]; end
        if ~isKey(P_data, ID), P_data(ID) = double(data.P); else, P_data(ID) = [P_data(ID), double(data.P)]; end
        B_data(ID) = double(data.B);
        
        STEP = 5; 
        selected_sensors = sensor_selector.Value; % Quali ID l'utente vuole vedere
        
        % Plotting con Filtro Sensori

updatePlot(axT, T_data, 'Temperatura (°C)', [10 35], STEP, selected_sensors);
        updatePlot(axH, H_data, 'Umidità (%)', [10 90], STEP, selected_sensors);
        updatePlot(axP, P_data, 'Pressione (Pa)', [100600 102000], STEP, selected_sensors);
        
        % Tabella Batterie (decrescente)
        ids = keys(B_data);
        if ~isempty(ids)
            batt_mat = zeros(length(ids), 2);
            for i = 1:length(ids)
                batt_mat(i, 1) = double(ids{i});
                batt_mat(i, 2) = double(B_data(ids{i}));
            end
            batt_mat = sortrows(batt_mat, 2, 'descend');
            uit.Data = num2cell(batt_mat);
        end
        
        % Calcolo statistiche (Media, Varianza, Min, Max)
        calcStatistics(selected_sensors);
    end

    % Calcolo e renderizzazione testo statistiche
    function calcStatistics(selected_ids)
        % funzione usata per il calcolo di media, varianza, min/max per
        % ogni campo dei sensori. I risultati vengono scritti nella colonna
        % a sx.
        if isempty(selected_ids)
            stats_text.Value = 'Nessun sensore selezionato.';
            return;
        end
        
        stats_str = {};
        for i = 1:length(selected_ids)
            id = selected_ids(i);
            if isKey(T_data, id)
                t_arr = T_data(id);
                stats_str{end+1} = sprintf('--- ID %d ---', id);
                stats_str{end+1} = sprintf('T: Med %.1f, Var %.2f', mean(t_arr), var(t_arr));
                stats_str{end+1} = sprintf('   Min %.1f, Max %.1f', min(t_arr), max(t_arr));
            end
            if isKey(H_data, id)
                h_arr = H_data(id);
                stats_str{end+1} = sprintf('H: Med %.1f, Var %.2f', mean(h_arr), var(h_arr));
                stats_str{end+1} = sprintf('   Min %.1f, Max %.1f', min(h_arr), max(h_arr));
            end
            if isKey(P_data, id)
                p_arr = P_data(id);
                stats_str{end+1} = sprintf('P: Med %.1f, Var %.2f', mean(p_arr), var(p_arr));
                stats_str{end+1} = sprintf('   Min %.1f, Max %.1f\n', min(p_arr), max(p_arr));
            end
        end
        stats_text.Value = stats_str;
    end

    function updatePlot(ax, map, labY, y_lim, STEP, selected_ids)
        % Aggiorna il grafico passato come ax con il valore in map
        % corrispondente alla chiave. Imposta la label e il limite su y,
        % poichè per x è uguale per i 3 grafici. STEP viene passato uguale
        % per tutti come incremento del tempo (asse x). L'aggiunta di
        % selected_ids permette di discriminare tra gli id selezionati
        % nella tabella di selezione.
        cla(ax);
        hold(ax, 'on');
        ks = keys(map);
        labels = {};
        maxL = 0;
        
        for i = 1:length(ks)
            k = ks{i};
            
            % Salta l'id se non è selezionato
            if ~ismember(k, selected_ids), continue; end
            
            valori = map(k);
            maxL = max(maxL, length(valori));
            c_idx = mod(double(k), length(colors)) + 1; % Colore legato all'ID
            
            plot(ax, 1:length(valori), valori, 'Color', colors(c_idx), 'LineWidth', 1.5);
            labels{end+1} = sprintf('ID %d', k);
        end
        
        ylabel(ax, labY); xlabel(ax, 'Campioni');
        ylim(ax, y_lim);
        
        if maxL > 0, xlim(ax, [0, ceil(maxL/STEP)*STEP]); end
        if ~isempty(labels), legend(ax, labels, 'Location', 'northeast'); end
        grid(ax, 'on');
    end

    %% === CHIUSURA APPLICAZIONE ===
    function closeApp(~, ~)
        fprintf('Chiusura in corso...\n');
        try stop(t); catch; end
        try delete(t); catch; end
        try release(obj_rtlsdr); catch; end
        try delete(fig); catch; end
    end
end