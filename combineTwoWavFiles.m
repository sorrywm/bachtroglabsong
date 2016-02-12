function newWav = combineTwoWavFiles(infile1, infile2, outfile)
    %Should check whether the two infiles are compatible
    %(same sampling frequency and number of channels)
    %and if so, combine the two and save as outfile
    %infile1 --> filename without suffix (either bin or wav)
    %infile2 --> filename without suffix (either bin or wav)
    %outfile --> where to save the combined file
        % Find the .bin file corresponding to today's date.
        % Modified to allow the case in which 
        % the recording is one of two (a or b).
        %binFileNoExt = findBinFile();
        binFileNoExt = findBinFileExt(AB{f});
        wavFile = [binFileNoExt '.wav'];
        disp('Looking for .bin and .wav files...');
        switch exist(wavFile, 'file')
            case 0
                % The .wav file does not exist. Attempt to convert the .bin file.
                disp('Converting .bin file to .wav file. This may take a few minutes.');
                tic;
                bin2wav(binFileNoExt);
                timetoconvertbin = toc;
            case 2
                % The .wav file already exists. Skip conversion.
                FEEDBACK = [FEEDBACK; ['WARNING: The .wav file already exists. Continuing without converting the .bin file.']];
                FEEDBACK = [FEEDBACK; ['WARNING: If there are problems, consider deleting the .wav file and try again.']];
            otherwise
                % Unknown conflict with the .wav file path.
                FEEDBACK = [FEEDBACK; ['WARNING: The file path ' wavFile ' caused an unknown problem. Extracting channels from the file may fail!!!']];
        end


        tic;
        % Start reading the BIG .wav file.
        %Open the .wav file (only once before looping thru channels).
        info = audioinfo(wavFile);
        %Because files are large, data will need to be parsed a few bits at a time.
        %e.g.: http://www.mathworks.com/matlabcentral/newsreader/view_thread/302506
        % construct the object, set the filename equal to your .wav file
        % set the SamplesPerFrame property to your desired value
        % NOTE: Reading 1MB at a time loads the entire 2-3 GB file in about 1 minute!
        h = dsp.AudioFileReader('Filename', wavFile, 'SamplesPerFrame', SPF);
        totalSteps = (info.TotalSamples - mod(info.TotalSamples, SPF)) / SPF;
        if mod(info.TotalSamples, SPF) > 0
             totalSteps = totalSteps + 1;
        end
        % New: Read number of channels from .wav file (info.NumChannels).
        audiodata = zeros(info.TotalSamples, info.NumChannels);
        stepNum = 0;
        while ~isDone(h)
            stepNum = stepNum + 1;
            pct = (100 * stepNum / totalSteps);
            pct = num2str(pct, '%02f');
            pct = pct(1:5);
            pct = [pct '%'];
            %disp(['Reading the ' num2str(NUMCHANNELS) '-channel .wav file ... ' pct]);
            disp(['Reading the ' num2str(info.NumChannels) '-channel .wav file ... ' pct]);
            try
                % read the audio frame (1,048,576 samples)
                audio = step(h);
                % keep ALL channels
                for i = 1:info.NumChannels
                    rowLow = ((i - 1) * info.TotalSamples) + ((stepNum - 1) * h.SamplesPerFrame) + 1;
                    if stepNum < totalSteps
                        rowHigh = rowLow + h.SamplesPerFrame - 1;
                        audiodata(rowLow:rowHigh) = audio(:,i);
                    else % Calculating rowHigh is different at the last step.
                        rowHigh = rowLow + (info.TotalSamples - ((totalSteps - 1) * h.SamplesPerFrame)) - 1;
                        clipSize = rowHigh - rowLow + 1;
                        audiodata(rowLow:rowHigh) = audio(1:clipSize,i);
                    end
                end
            catch ME
                if (strcmp(ME.identifier,'dspshared:system:libOutFromMmFile'))
                    %"the audio input stream has become unresponsive"
                    %fprintf(errorout, 'Issue with audio input stream.');
                    %error('Issue with input stream for channel %s\n',channelNumber)
                    error('There was an unknown issue with the audio input stream.');
                    continue
                else
                    ME.identifier
                    rethrow(ME)
                end
            end
        end
end
