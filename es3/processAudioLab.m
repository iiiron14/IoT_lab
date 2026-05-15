function processedAudio = processAudioLab(audioFrame, equalizerValues, fs, tot, last_199_frames)
    % Process the audio frame using equalizer values (simulated frequency bands)
    % Apply band-pass filters or adjust gains based on equalizer values

    % Simple example: multiply different frequency bands by slider values
    processedAudio = zeros(tot,1);  % Initialize output
    y = zeros(1, tot + 199);
    % Loop over each frequency band
    for i = 1:6
        h_filtro = load(strcat('coeff', num2str(i) ,'.txt'));
        y = miofir(h_filtro, [last_199_frames ; audioFrame]');
        y = y*equalizerValues(i);
        processedAudio = processedAudio + y(200:end)';
    end
end