function filtercombineExcelsheets(ssfolder, watchfilter)
    %Combine all spreadsheets in ssfolder
    %If watchfilter is true, only include dates where
    %recording notes indicate that someone was watching
    %and taking notes during the recording.
    outname = [ssfolder 'Combined' date '.xlsx'];
    if strcmp(watchfilter,'TRUE')
         outname = [ssfolder 'CombinedFiltered' date '.xlsx'];
    end
    outdata = []
    excelFiles = dir([ssfolder '/*.xlsx']);
    for f=1:length(excelFiles)
        doadd = 1; %switch to zero if filtered
        excelFile = fullfile(ssfolder, excelFiles(f).name);
        [~,~,raw] = xlsread(excelFile);
        [~,~,header] = xlsread(excelFile, 'Sheet1', 'A2:R2', 'basic');
        %Compare header to the most recent header line.
        %If it is shorter, add the missing columns to raw.
        if strcmp(watchfilter,'TRUE')
            doadd = checkNotes(raw,header);
        end
        if doadd == 1
            outdata = [outdata; raw];
        end
    end
    xlswrite(outname,outdata)
end

function addsheet = checkNotes(rawdata,rawheader)
    %Looks for times in (Recording) Notes column
    %If present, doadd = 1, indicating to keep the spreadsheet
    %If absent, doadd = 0
    addsheet = 0;
    noteindex = find(strcmp(header, 'Notes'));    
    [nrows,ncolums]=size(raw) 
    for r=1:nrows
        notestr = raw{r,noteindex}
        hasnum = regexp(notestr,'-?\d+\.?\d*|-?\d*\.?\d+','match')
        if length(hasnum) > 0
            addsheet = 1;
            break
        end
    end
end
