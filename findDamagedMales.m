function findDamagedMales(dateArg)
%Use recording spreadsheet to identify males (or females) with damaged wings.
%Save filenames of recordings to match up with the output of SummarizeSongStatdist.R
%Pull code from makeWaves and makeCourtshipPlot
%Define global variables for use in functions:
    global SPREADSHEETPATH; 
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    global NUMCHANNELS;
    global EXCLUDECHANNELS;
    global SAVETOPATH;
    global FOLDERMAPFILE;
    optsfile = strcat('optsfiles/',dateArg,'.opts.mat');
    if exist(optsfile, 'file') == 2
        load(optsfile);
    else
        %Modify when done to include only necessary variables
        NUMCHANNELS = 32;
        EXCLUDECHANNELS = [];
        FEEDBACK = {};
        RECORDINGSPATH = '/global/scratch/wynn/SoundData/';
        RECORDINGNAMESCHEME = '*ecording*'; %changed 11/21: could be upper or lowercase
        BINFILENAMESCHEME = '*.bin';
        BINFUNCTIONSPATH = '/global/home/users/wynn/repos/omnivore';
        SPREADSHEETPATH = '/global/scratch/wynn/AllCourtshipSongRecordings/'; %modify to exclude '/'?
        EXCELNAMESCHEME = '*Recording*.xls*';
        SAVETOPATH = '/global/scratch/wynn/NewPerSpeciesRecordingsMono/';
        BUTTERDIR = '/global/home/users/wynn/repos/bachtroglabsong';
        DATEFORMAT = 'mmddyyyy';
        DATEFORMAT2 = 'yyyy-mm-dd';
        DATEFORMAT3 = 'mmddyy';
        SPF = 1048576;
        %Comment here is not working?
        %%%%%%%% FOLDERMAPFILE = '/global/home/users/wynn/MATLABOpts/folderMap.mat';
        FOLDERMAPFILE = 'folderMap.mat' %save in same directory with script
        SAVEFILT = 'raw';
        FILTCUT = 200;
        AB = {''};
        save(optsfile);
    end
    switch nargin
        case 0
            DATETODAY = now;
            dateArg = datestr(now, 'mmddyyyy');
        case 1
            %DATETODAY = datenum(dateArg, 'mmddyyyy'); switched to allow different specifications of date
            fprintf('dateArg: [%s]\n',dateArg)
            switch length(dateArg)
                case 6
                    DATETODAY = datenum(dateArg, 'mmddyy')
                case 8
                    DATETODAY = datenum(dateArg, 'mmddyyyy')
                case 10
                    DATETODAY = datenum(dateArg, 'yyyy-mm-dd')
                otherwise
                    error('Issue with dateArg: %s', dateArg)
            end
    end
    %Use another folder for saving wing damage info
    DAMAGEPATH = '/global/scratch/wynn/WingDamageInfo/';
    %Find recording spreadsheet
    excelFileArr = findExcelFileArr();
    if length(excelFileArr) == 2
        AB = {'a' 'b'}; %set up for switch 
        %Also change filenames to include A or B.
    end
    
    for f = 1:length(excelFileArr)
        excelFile = excelFileArr{f};
        %Previous range was too narrow for most recent files.... change from R to AB.
        xlRange = 'A3:AB34';
        headerRange = 'A2:AB2'; %assumes two lines of header (first line is 'female' and 'male')
        try
            %to do: catch if wrong number of columns
            %helpful: columns 16 and on will be NaN if older "style"
            %if older style, maleSpecies is in column 10
            [~,txt,raw] = xlsread(excelFile, 'Sheet1',  xlRange, 'basic');
            [~,htext,header] = xlsread(excelFile, 'Sheet1', headerRange, 'basic');
        catch ME
            ME.identifier
            excelFile
            class(excelFile)
            error('excelFile is not a string')
        end
        % Generate a list of filenames that will be saved.
        %fileNameCleaned is now written out each time.... doesn't need to be an array
        %Find Notes cell
        %Some issues if header contains non-string values. 
        %Currently looping to find Notes.
        whichNote = [];
        for h = 1:length(header)
            if ischar(header{h})
                if length(strfind(header{h},'Notes')) > 0
                    whichNote = h;
                    break
                end
            end
        end
        %try
            %hasNote = strfind(header, 'Notes');
        %    hasNote = strfind(htext, 'Notes');
        %catch MEnote
        %    disp(header)
        %    disp(class(header))
        %    rethrow(MEnote)
        %end
        %whichNote = find(not(cellfun('isempty', hasNote))); %hasNote determines whether this is an index of header/raw or htext/txt
        if length(whichNote) == 0
            error('Notes column not found for %s\n',excelFile)
        end
        %new: use header to find maleSpecies column (second occurrence of 'Species')
        spindex = find(strcmp(header, 'Species'));
        if length(spindex) < 2
            error('Male species column not found for %s\n',excelFile)
        end
        for i = 1:NUMCHANNELS
            % First check if this channel should be excluded.
            if ismember(i, EXCLUDECHANNELS)
                continue; % Don't bother looking at this row in the spreadsheet; move on to the next row.
            end
            % Convert Excel's date format (e.g. 8/5/2015) to yyyy-mm-dd (e.g. 2015-08-05).
            dateRaw = raw{i, 1}; %date may not be text format
            if strcmp(dateRaw, '') || strcmp(dateRaw, 'NA') || sum(isnan(dateRaw)) > 0
                dateString = '0000-00-00';
            else
                try
                    if isnumeric(dateRaw)
                        dateNum = datenum(x2mdate(dateRaw));
                        dateString = datestr(dateNum, 'yyyy-mm-dd');
                    elseif ischar(dateRaw)
                        %set date to zero if 'notes' in this column
                        notefind = strfind(dateRaw,'otes');
                        if length(notefind) == 0
                            dateNum = datenum(dateRaw, 'mm/dd/yyyy');
                            dateString = datestr(dateNum, 'yyyy-mm-dd');
                        else
                            dateString = '0000-00-00';
                        end
                    else
                        error('Issue with type of dateRaw %s.',class(dateRaw))
                        exit
                    end
                catch ME
                    if isnumeric(dateRaw)
                        firstrowmsg = ['Issue with dateRaw: ', num2str(dateRaw), ', class: ', class(dateRaw)]
                    else
                        firstrowmsg = ['Issue with dateRaw: ', dateRaw, ', class: ', class(dateRaw)]
                    end
                    msg = [firstrowmsg, '\n', ...
                          'contents of 2nd column: ', raw{i, 2}, ', class: ', class(raw{i, 2}), '\n',...
                          'contents of 3rd column: ', raw{i, 3}, ', class: ', class(raw{i, 3}), '\n',...
                          'contents of 4th column: ', raw{i, 4}, ', class: ', class(raw{i, 4}), '\n',...
                          'contents of 5th column: ', raw{i, 5}, ', class: ', class(raw{i, 5}),'\n'];
                    causeException = MException('MATLAB:myCode:dateRaw',msg);
                    ME = addCause(ME,causeException);
                    rethrow(ME)
                end
            end
            maleSpecies = raw{i, spindex(2)};
            if isnumeric(maleSpecies)
                maleSpecies = num2str(maleSpecies);
            end
            %Strip spaces from the string.
            try
                maleSpecies = strtrim(maleSpecies);
            catch ME
                error(['issue with maleSpecies :' maleSpecies ', ' class(maleSpecies)])
            end
            %If this field is either blank or NA, exclude this row.
            if sum(strcmp(maleSpecies,{'','NA','NaN','N\A','N/A'})) > 0
                EXCLUDECHANNELS = [EXCLUDECHANNELS; i];
                %fileNameCleaned{i} = 'blank';
                continue; % Don't bother looking at this row in the spreadsheet; move on to the next row.
            end
            if isnan(raw{i, 16})
                maleStrain = raw{i, 11}; %added 11/16/15
            else
                maleStrain = raw{i, 13}; %added 6/4/15
            end
            if isnumeric(maleStrain)
                maleStrain = num2str(maleStrain);
            end
            femaleSpecies = raw{i, 6}; %replaced previous row 6/4/15
            femaleStrain = raw{i, 7}; %added 8/8/15
            if isnumeric(femaleStrain)
                femaleStrain = num2str(femaleStrain);
            end
            if sum(strcmp(maleStrain, {'', 'NA', 'NaN'})) > 0
                maleStrain = ['_' maleStrain]; % Make filename more readable if there is a strain.
            end
            if sum(strcmp(femaleStrain, {'', 'NA', 'NaN'})) > 0
                femaleStrain = ['_' femaleStrain]; % Make filename more readable if there is a strain.
            end

            fileName = [dateString AB{f} '_Channel_' num2str(i, '%02d') '_' maleSpecies maleStrain '-male__' ...
                       femaleSpecies femaleStrain '-female']; %changed order of filename parts 8/21/15
            fileNameCleaned = regexprep(fileName, '[^a-zA-Z0-9_.()]','-');
            %save this, along with the data on male and female damage.
            %disp(raw{i,whichNote})
            [maleWings, femaleWings] = characterizeRowDamage(raw{i,whichNote},dateArg);
            %[maleWings, femaleWings] = characterizeRowDamage(txt{i,whichNote});
            %still need folderMap, because output files need to be sorted by species
            %Determine species folder for output file (using folderMap)
            % Load or generate folderMap.
            try
                folderMap = getfolderMap();
            catch MEfm
                error('Issue with FOLDERMAPFILE: %s\n',FOLDERMAPFILE)
            end
            folderName = findFolder(folderMap, maleSpecies, maleStrain);
            %Write or append file for this species
            outfile = [DAMAGEPATH '/DamageInfoFor' folderName '.csv'];
            formatSpec = '%s,%s,%s\n';
            if exist(outfile,'file') ~= 2
                %Write header row
                fid = fopen(outfile,'a');
                fprintf(fid,formatSpec,'Filename', 'MaleWings', 'FemaleWings');
                fprintf(fid,formatSpec,[fileNameCleaned '-raw.wav'], maleWings, femaleWings);
            else
                fid = fopen(outfile,'a');
                fprintf(fid,formatSpec,[fileNameCleaned '-raw.wav'], maleWings, femaleWings);
            end
            fclose(fid);
        end
    end
end

function [maleDamage,femaleDamage] = characterizeRowDamage(notecell,dateArg)
    %feed in text from the "Recording Notes" cell, and get whether there is male or female damage
    %slight is a T/F (or y/n) variable: include "slightly" damaged wings?
    %as damaged wings?
    %output: "damaged" or "whole"
    maleDamage = 'whole';
    femaleDamage = 'whole';
    %If the cell is classified as numeric, it's probably empty.
    if isnumeric(notecell)
        return
    end
    %if length(regexpi(slight,'(Y|T)')) == 0
    %dre: identifies any damage, whether slight or not
    dre = '\<(torn|shredded|wrink|curly|damage|completely|fold|missing|chip|tear|crumple|shrivel)\w*';
    %else
    %dres: identifies only damage that is not preceded by "slight" or "small"
    dres = '(?<!slight |slightly |small )\<(torn|shredded|wrink|curly|damage|completely|fold|missing|chip|tear|crumple|shrivel)\w*';
    %end
    try
        splitnotes = strsplit(notecell,{'; ',', ',';',','}); %split with a space first
    catch MEsn
        disp(notecell)
        disp(class(notecell))
        rethrow(MEsn)
    end
    for sn=1:length(splitnotes) 
        %use strfind or regexp? regexpi! (case insensitive)
        %tmb = strfind(splitnotes{sn},'male'); %should include 1 if at beginning
        %tms = strfind(splitnotes{sn},' male'); %should be non-zero length if male after space
        %to do: modify the following to only look for 'both' at the beginning of the whole string (not just a word)
        tm = regexpi(splitnotes{sn},'^both|\<male\w*');
        tf = regexpi(splitnotes{sn},'female|^both');
        td = regexpi(splitnotes{sn},dre); %hopefully finds any of the options at the beginning of a word
        tds = regexpi(splitnotes{sn},dres);
        %determine if 'male' and 'female' are interleaved with damage info
        if (length(tm) > 0 & length(tf) > 0) & length(td) > 0
            interleaf1 = (td > tm) & (td < tf);
            interleaf2 = (td > tf) & (td < tm);
            if sum(interleaf1) > 0 | sum(interleaf2) > 0
                %split the string at the first male/female occurrence after a damage occurrence.
                mfi = [tm tf];
                mmfi = min(mfi);
                try
                    fdi = min(td(td>mmfi)); %first "damage" after earliest instance of "male" or "female"
                catch MEfdi
                    fprintf('Issue ordering sex and damage for %s.\n',dateArg);
                    rethrow(MEfdi)
                end
                fmfi = min(mfi(mfi>fdi)); %first "male" or "female" after one "damage" and one "male" or "female"
                fullnote = splitnotes{sn};
                ilnotes = {fullnote(1:(fmfi-1)),fullnote(fmfi:end)}; %split the note after one "damage" and one "male" or "female"
                for il=1:2
                    tm = regexpi(ilnotes{il},'^both|\<male\w*');
                    tf = regexpi(ilnotes{il},'female|^both');
                    td = regexpi(ilnotes{il},dre); %hopefully finds any of the options at the beginning of a word
                    tds = regexpi(ilnotes{il},dres);
                    if length(tm) > 0 && length(tds) > 0
                        maleDamage = 'damaged';
                    elseif length(tm) > 0 && length(td) > 0 %assume any matches are "slight"
                        maleDamage = 'slight';
                    end
                    if length(tf) > 0 && length(tds) > 0
                        femaleDamage = 'damaged';
                    elseif length(tf) > 0 && length(td) > 0
                        femaleDamage = 'slight';
                    end
                end
                continue
            end
        end
        if length(tm) > 0 && length(tds) > 0
            maleDamage = 'damaged';
        elseif length(tm) > 0 && length(td) > 0 %assume any matches are "slight"
            maleDamage = 'slight';
        end
        if length(tf) > 0 && length(tds) > 0
            femaleDamage = 'damaged';
        elseif length(tf) > 0 && length(td) > 0
            femaleDamage = 'slight';
        end
    end
end
