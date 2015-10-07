function GetWavDataMultipleSpreadsheets_matt(sfolder, direrror, ...
    nameerror, wavnamout, getwavlog)
    if nargin < 5
        getwavlog = fullfile(sfolder,'GetWavDataLog.txt');
        if nargin < 4
            wavnamout = fullfile(sfolder,'wavNamingLog.txt');
            if nargin < 3 
                nameerror = fullfile(sfolder,'NamingErrors.txt');
                if nargin < 2 
                    direrror = fullfile(sfolder,'DirectoryErrors.txt');
                end
            end
        end
    end
    fprintf('Running GetWavData for %s at %s.\n',sfolder,datestr(now));
    addpath('D:\BackupFromDesktop072815\MATLABCode\MatlabSeminarDemos',...
        'D:\BackupFromDesktop072815\MATLABCode\MATLAB') %directories for wavNaming and bin2wav
    recdir = 'D:/SoundData'; %directory where 'Recordings' folders are
    direrrorout = fopen(direrror,'at'); %file to write errors in directory naming
    getwavout = fopen(getwavlog,'at');
    %Get a list of all worksheets in the folder.
    listing = dir(fullfile(sfolder,'*.xlsx'));
    %For each worksheet in the folder,
    for file = listing' %listing appears to be a row array.
        %tic;
        %Map the name of the worksheet to the directory where the .wav file
        %should be.
        fn = file.name;
        fprintf(getwavout,'Parsing %s at %s.\n',fn,datestr(now));
        nosuff = strrep(fn,'.xlsx',''); %eliminate file suffix
        dings = strfind(nosuff,'dings');
        if isempty(dings)
            wplural = strrep(nosuff,'ding','dings');
        else
            wplural = nosuff;
        end
        if exist(fullfile(recdir,wplural),'dir') == 0
            %try adding a '20' to the name
            finaldir = strcat(wplural(1:(length(wplural)-2)),'20',...
                wplural((length(wplural)-1):length(wplural)));
        elseif exist(fullfile(recdir,wplural),'dir') == 7
            finaldir = wplural;
        else
            fprintf(direrrorout,'%s is not a directory.\n', wplural);
            continue
        end
        %find the associated .bin file (if there is one),
        binfiles = dir(fullfile(recdir,finaldir,'*.bin'));
        if isempty(binfiles)
            fprintf(direrrorout,'No .bin files in %s.\n',finaldir);
            continue
        elseif length(binfiles) > 1
            fprintf(direrrorout,'Multiple .bin files in %s.\n',finaldir);
            continue
        else
            wavfiles = dir(fullfile(recdir,finaldir,'*.wav'));
            if length(wavfiles) > 1
                fprintf(direrrorout,'Multiple .wav files in %s.\n',finaldir);
                continue
            elseif isempty(wavfiles)
                %Run bin2wav
                bfname = binfiles(1).name;
                binbase = strrep(bfname,'.bin','');
                bin2wav(fullfile(recdir,finaldir,binbase));
                wavfiles = dir(fullfile(recdir,finaldir,'*.wav'));
            end
            %and run wavNaming.
            wname = wavfiles(1).name;
            fixname = wavNaming_matt(fullfile(sfolder,fn),...
                fullfile(recdir,finaldir,wname),...
                nameerror,wavnamout);
            if fixname == 1
                fprintf(getwavout,'Naming issue for %s; fix and re-run.\n',fn);
            elseif fixname == 2
                fprintf(getwavout,'No more channels for %s; continuing.\n',fn);
                continue
            end
        end
        fprintf(getwavout,'Finished getting files from %s at %s.\n',fn,datestr(now));
        %etime = toc;
        %fprintf(getwavout,'Elapsed time is %s seconds.\n',num2str(etime));
    end
    fclose(direrrorout);
    fclose(getwavout);
    fprintf('Finished running GetWavData for %s at %s.\n',...
        sfolder,datestr(now));
end