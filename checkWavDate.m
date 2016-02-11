function wavdatematch = checkWavDate(wavDate, wavFile)
    % check to make sure the .wav or .bin file was created
    % on the same date as in the folder name.
    % returns 1 if date string found, 0 if not.
    wavdatematch = 0;
    dateInFilename = strfind(wavFile, wavDate);
    if length(dateInFilename) > 0
        wavdatematch = 1;
    end
end
