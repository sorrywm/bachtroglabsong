function concatenateWavFiles(wavfolder, outname, outfs)
    %Concatenate all .wav files in wavfolder
    %Write as a single .wav file
    %with sampling frequency outfs
    wavlist = dir([wavfolder '/*.wav']);
    for w=1:length(wavlist)
        if exist('outwav','var')~=1
            outwav=[];
        end
        isBadFile = strfind(wavlist(w).name,'._');
        if isempty(isBadFile)
            [inwav, infs] = audioread([wavfolder '/' wavlist(w).name]);
            if infs ~= outfs
                sprintf(['Sampling frequency for %s (%d) not equal to '...
                         'desired sampling frequency (%d); converting.'],...
                         wavlist(w).name, infs, outfs);
                [P,Q] = rat(outfs/infs);
                inwav = resample(inwav,P,Q);
            end
            outwav = vertcat(outwav,inwav);
        end
    end
    audiowrite(outname, outwav, outfs);
end