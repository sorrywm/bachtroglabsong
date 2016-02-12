function [d, dfilt] = ReadAndFilterWavFile(outname, wav_file, song_range, filtcut, fs, dofilter)
    %First, check whether data already exists:
    %If d exists but dfilt does not, just filter d.
    %If data does not exist, grab the wav file.
    %If the wav file does not exist, error out.
    writeout = 'FALSE';
    if exist(strcat(outname,'.mat'),'file') == 2
        prevdata = load(strcat(outname,'.mat'));
        d = prevdata.d;
    else   
        %Generate a data file from the .wav file
        fprintf('Grabbing song from wav file %s.\n', wav_file);
        if ~isempty(song_range)
            d = audioread(wav_file,song_range);
        else
            d = audioread(wav_file);
        end
    end
    %Filter if requested
    if strcmp(dofilter,'TRUE')
        refilter = 'TRUE';
        writeout = 'TRUE';
        if exist('prevdata','var')==1
            if isfield(prevdata,'filtcut')
                if prevdata.filtcut == filtcut
                    refilter = 'FALSE';
                    writeout = 'FALSE';
                    dfilt = prevdata.dfilt;
                end
            end
        end
        if strcmp(refilter,'TRUE')    
            dfilt = tybutter(d,filtcut,fs,'high');
        end
    end
    %Write output file            
    if strcmp(writeout,'TRUE')
        save(strcat(outname,'.mat'),'d','dfilt','filtcut');
    end
end
