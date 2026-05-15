deviceWriter = audioDeviceWriter('SampleRate', audio_fs);
frameSize = 1024; % Dimensione standard del buffer (potenza di 2)

for i = 1:4
    % --- PARTE 1: Tua Elaborazione ---
    % Immaginiamo che qui generi 'y' (es. un vettore di 5 secondi)
    
    % Assicurati che y sia un vettore colonna
    if isrow(y), y = y'; end 
    
    % --- PARTE 2: Streaming del blocco 'y' ---
    numSamples = length(y);
    for startIdx = 1:frameSize:numSamples
        endIdx = min(startIdx + frameSize - 1, numSamples);
        
        % Estrai il pezzettino di audio
        buffer = y(startIdx:endIdx);
        
        % Se l'ultimo pezzetto è più corto del frameSize, 
        % deviceWriter potrebbe lamentarsi: lo riempiamo di zeri (padding)
        if length(buffer) < frameSize
            buffer = [buffer; zeros(frameSize - length(buffer), size(y,2))];
        end
        
        % Invia alla scheda audio
        deviceWriter(buffer); 
    end
end

release(deviceWriter);