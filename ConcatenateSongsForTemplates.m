function ConcatenateSongsForTemplates()
    %For a list of songs, load and concatenate the data files, 
    %saving the output for use in CreateTemplates.
    %If the list does not exist, generate one with all files and
    %one with a random subset (1 or 2 from each date.
    %Assume script is run from the directory with the .wav files.
    %To do: strip ._ from filenames, always loop over indices.

    outfull = 'AllEgSongs';
    outsub = 'TrainingSet';
    outdir = 'DataForTemplates';
    sflist = 'Subfilelist.txt';
    fflist = 'Fullfilelist.txt';

    %Get the full file list.
    if exist(fflist,'file') == 2
        fullfid = fopen(fflist,'r');
        fullfilescell = textscan(fullfid,'%s','Delimiter','\n');
        fullfiles = fullfilescell{1};
        %fullfiles = fscanf(fullfid, '%s');
        fclose(fullfid);
    else
        %List all .wav files
        fullfileslist = dir('*.wav');
        fullfiles = {};
        fullfid = fopen(fflist,'w');
        for ff = 1:length(fullfileslist)
            try
                fprintf(fullfid,'%s\n',strrep(fullfileslist(ff).name,'._',''));
            catch ME2
                display(fullfileslist(ff).name)
                rethrow(ME2)
            end
            fullfiles = [fullfiles strrep(fullfileslist(ff).name,'._','')];
        end
        fclose(fullfid);
    end
    %Get subset to make into the training set.
    if exist(sflist,'file') == 2
        subfid = fopen(sflist,'r');
        subfilescell = textscan(subfid,'%s','Delimiter','\n');
        subfiles = subfilescell{1};
        %subfiles = fscanf(subfid,'%s');
        fclose(subfid);
    else
        subchannels = {};
        for f = 1:length(fullfiles)
            try
                ss = strsplit(fullfiles{f}, '_');
            catch ME1
                %display(fullfiles{f})
                display(class(fullfiles))
                display(length(fullfiles))
                display(fullfiles{1})
                rethrow(ME1)
            end
            try
                sj = strjoin([ss(1:3)],'_');
                subchannels = [subchannels sj];
            catch ME
                display(ss)
                rethrow(ME)
            end
        end
        try
            scunique = unique(subchannels);
        catch ME3
            disp(class(subchannels))
            subchannels(1)
            rethrow(ME3)
        end
        subfiles = {};
        for sc = 1:length(scunique)
            sf = dir(strcat(scunique{sc},'*.wav'));
            if length(sf) > 2
                toadd = datasample(sf, 2, 'Replace', false);
            else
                try
                    toadd = datasample(sf, 1);
                catch MEds
                    disp(sf)
                    disp(scunique{sc})
                    rethrow(MEds)
                end
            end
            %length(toadd)
            for ta = 1:length(toadd)
                subfiles = [subfiles strrep(toadd(ta).name,'._','')];
            end
        end
    end
    [subfid,message] = fopen(sflist,'w');
    for sf = 1:length(subfiles)
        try
            fprintf(subfid,'%s\n',subfiles{sf}); %issue with cell arrays - try indexing?
        catch ME4
            disp(sflist)
            disp(subfid)
            disp(message)
            disp(subfiles{sf})
            rethrow(ME4)
        end
    end
    fclose(subfid);

    %Generate concatenated data files.
    subdat=[];
    fulldat=[];
    fs = 6000;
    for f = 1:length(fullfiles)
        try
            [song, fs] = audioread(fullfiles{f});
        catch ME5
            disp(fullfiles{f})
            rethrow(ME5)
        end
        if fs == 6000
            fulldat = vertcat(fulldat, song);
            if sum(ismember(fullfiles{f},subfiles)) > 0
                subdat = vertcat(subdat, song);
            end
        else
            sprintf('Different sampling rate for %s: %s.\n',fullfiles{f},num2str(fs));
        end
    end
    
    %Check for output directory existence
    if exist(outdir, 'dir') ~= 7
        mkdir(outdir);
    end
    
    %Write out song files.
    audiowrite([outdir '/' outfull '.wav'],fulldat, fs)
    audiowrite([outdir '/' outsub '.wav'], subdat, fs)
    
    %Write out data files.
    d = fulldat;
    save(strcat(outdir,'/',outfull,'.mat'),'d');
    d = subdat;
    save(strcat(outdir,'/',outsub,'.mat'),'d');
end