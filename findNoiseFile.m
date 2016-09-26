function noisefile = findNoiseFile(filename,wsignal)
    %find the noise templates filename based on the outname
    %e.g.: 2015-07-09_Channel_32_Noise.wav_datasignal1456789101112signalpeaks.mat
    %modify for use with a/b names
    noisedir = '/global/scratch/wynn/ClusteringOutputPerSpecies/ForNoise';
    noisefile = [];
    sf = strsplit(filename,'_');
    ab = [strfind(sf{3},'a') strfind(sf{3},'b')];
    if length(ab) == 0
        ss = strcat(noisedir, '/', sf{1}, '*', sprintf('%d',wsignal), '*');
        nfs = dir(ss);
        if length(nfs) == 1
            noisefile = strcat(noisedir,'/',nfs(1).name);
        else
            fprintf('Noise file for %s (%s) not found.\n',filename,ss);
        end
    else
        fprintf('%s needs a corresponding a/b noise file.',filename);
    end
end