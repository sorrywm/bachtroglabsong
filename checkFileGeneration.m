%%Check whether all files have been generated for a given spreadsheet.
%%Output: a line of text with '<date> is complete/incomplete.'
function checkFileGeneration(dateArg)
    clearvars -except dateArg
    global NUMCHANNELS;
    global EXCLUDECHANNELS;
    global SAVETOPATH;
    global SAVEFILT;
    global FILTCUT;
    global DATETODAY;
    global FEEDBACK;
    global SPREADSHEETPATH;
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    global FOLDERMAPFILE;
    outfile = strcat('/global/scratch/wynn/RunStatus/',dateArg,'.txt');
    fileID = fopen(outfile, 'w');

    %Load options
    switch nargin
        case 0
            DATETODAY = now;
            dateArg = datestr(now, 'mmddyyyy');
        case 1
            switch length(dateArg)
                case 6
                    DATETODAY = datenum(dateArg, 'mmddyy');
                case 8
                    DATETODAY = datenum(dateArg, 'mmddyyyy');
                case 10
                    DATETODAY = datenum(dateArg, 'yyyy-mm-dd');
                otherwise
                    error('Issue with dateArg: %s', dateArg)
            end
    end
    
    % Optional: load these variables from a file ('dateArg'.opts.mat).
    % File must be in MATLAB's path.
    % Important: move/delete older file before re-running the same date.
    %modified so it will NOT load
    optsfile = strcat('nonexistentoptsfiles/',dateArg,'.opts.mat');
    if exist(optsfile, 'file') == 2
        load(optsfile);
    else
        NUMCHANNELS = 32;
        EXCLUDECHANNELS = [];
        FEEDBACK = {};
        RECORDINGSPATH = '/global/scratch/wynn/SoundData/';
        RECORDINGNAMESCHEME = '*ecording*';
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
        FOLDERMAPFILE = 'folderMap.mat'; %save in same directory with script
        SAVEFILT = 'raw';
        FILTCUT = 200;
        AB = {''};
        %save(optsfile);
    end

    %Load folder map
    folderMap = getfolderMap();

    %Find Excel file
    excelFileArr = findExcelFileArr();
    if length(excelFileArr) == 2
        AB = {'a' 'b'}; %set up for switch 
        %Also change filenames to include A or B.
    end
    
    for f = 1:length(excelFileArr)
        excelFile = excelFileArr{f};
        xlRange = 'A3:R34';
        headerRange = 'A2:R2'; %assumes two lines of header (first line is 'female' and 'male')
        %[~, txt, ~] = xlsread(excelFile, 'Sheet1',  xlRange);
        try
            %to do: catch if wrong number of columns
            %helpful: columns 16 and on will be NaN if older "style"
            %if older style, maleSpecies is in column 10
            %new: instead, use the header, and search for the 2nd occurrence of "species"
            [~,~,raw] = xlsread(excelFile, 'Sheet1',  xlRange, 'basic');
            [~,~,header] = xlsread(excelFile, 'Sheet1', headerRange, 'basic');
        catch ME
            ME.identifier
            excelFile
            class(excelFile)
            error('excelFile is not a string')
        end
    
        % Generate a list of filenames that will be saved.
        %filePathsNoExt = {};
        filePathsNoExt = cell(1, NUMCHANNELS);
        for i = 1:NUMCHANNELS
            % First check if this channel should be excluded.
            if ismember(i, EXCLUDECHANNELS)
                %filePathsNoExt = [filePathsNoExt; 'blank']; % Make a blank placeholder for the exlcluded channel.
                filePathsNoExt{i} = 'blank';
                continue; % Don't bother looking at this row in the spreadsheet; move on to the next row.
            end
            % Convert Excel's date format (e.g. 8/5/2015) to yyyy-mm-dd (e.g. 2015-08-05).
            %dateRaw = txt{i, 1};  %always column 1
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
                        firstrowmsg = ['Issue with dateRaw: {', num2str(dateRaw), '}, class: ', class(dateRaw)]
                    else
                        firstrowmsg = ['Issue with dateRaw: [', dateRaw, '], class: ', class(dateRaw)]
                    end
                    %msg = ['Issue with dateRaw: ', num2str(dateRaw), class(dateRaw), ...
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
            %if isnan(raw{i, 16})
            %    maleSpecies = raw{i, 10};
            %else
            %    maleSpecies = raw{i, 12}; %always column 12
            %end
            %new: use header to find maleSpecies column (second occurrence of 'Species')
            spindex = find(strcmp(header, 'Species'));
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
                %filePathsNoExt = [filePathsNoExt; 'blank']; % Make a blank placeholder for the excluded channel.
                filePathsNoExt{i} = 'blank';
                continue; % Don't bother looking at this row in the spreadsheet; move on to the next row.
            elseif sum(strcmp(maleSpecies, {'unknown','41869'})) > 0
                %Figure out where these are cropping up!
                fprintf('Problematic maleSpecies in %s\n',dateToday)
                [raw{i,:}]
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

            %fileName = [dateString '_' maleSpecies maleStrain '-male__' femaleSpecies ...
            %    femaleStrain '-female__channel_' num2str(i, '%02d')]; %replaced previous line 8/8/15
            fileName = [dateString AB{f} '_Channel_' num2str(i, '%02d') '_' maleSpecies maleStrain '-male__' ...
                       femaleSpecies femaleStrain '-female']; %changed order of filename parts 8/21/15
            fileNameCleaned = regexprep(fileName, '[^a-zA-Z0-9_.()]','-');
            folderName = findFolder(folderMap, maleSpecies, maleStrain);
            folderPath = [SAVETOPATH folderName '/'];
            try
                verifyPath(folderPath, i);
            catch
                %folderPath is long and sometimes gets cut off. Print maleSpecies.
                error('Problematic maleSpecies: %s\n', maleSpecies)
            end
            filePathNoExt = [folderPath fileNameCleaned];
            %filePathsNoExt = [filePathsNoExt; filePathNoExt];
            filePathsNoExt{i} = filePathNoExt;
        end

        % Before attempting to convert the .bin file or read the .wav file
        % (both quite slow), determine if ALL of the channels from this
        % recording session have already been extracted and filtered.
        oneIsNotDone = 0;
        for i = 1:length(filePathsNoExt)
            if ismember(i, EXCLUDECHANNELS)
                continue; % This channel is excluded, so a file will never be made.
                % Do not try to see if the file exists; move on to the next file.
            end
            switch SAVEFILT
                case 'raw'
                    if exist([filePathsNoExt{i} '-raw.wav'], 'file') == 0
                        oneIsNotDone = 1;
                        break;
                    end
                case 'filt'
                    if exist([filePathsNoExt{i} '-filt' num2str(FILTCUT) '.wav'], 'file') == 0
                        oneIsNotDone = 1;
                        break;
                    end
                case 'both'
                    if exist([filePathsNoExt{i} '-raw.wav'], 'file') == 0 || ...
                          exist([filePathsNoExt{i} '-filt' num2str(FILTCUT) '.wav'], 'file') == 0
                        oneIsNotDone = 1;
                        break;
                    end
                otherwise
                    %write to messages that this value should be raw/filt/both
                    %but assume it's both.
                    FEEDBACK = [FEEDBACK; ['SAVEFILT should be raw, filt, or both. Assuming both for ' datestr(DATETODAY, 'yyyy-mm-dd')]];
                    FEEDBACK
                    if exist([filePathsNoExt{i} '-raw.wav'], 'file') == 0 | ...
                          exist([filePathsNoExt{i} '-filt' num2str(FILTCUT) '.wav'], 'file') == 0
                        oneIsNotDone = 1;
                        break;
                    end
            end
        end
        if oneIsNotDone == 0
            % Give some FEEDBACK
            fprintf(fileID, 'All of the specified files for %s already exist. Nothing to do.\n', datestr(DATETODAY, 'yyyy-mm-dd'))
        else
            fprintf(fileID, 'At least one of the files for %s has not been generated. Try re-running makeWaves.\n', datestr(DATETODAY, 'yyyy-mm-dd'))
        end
    end
    fclose(fileID);
end

%Subfunctions from makeWaves_savio_raw
function folderName = findFolder(folderMap, maleSpecies, strain) %added strain and specified output as fullDir 6/4/15
    global DATETODAY;
    %switched to saving file to 'UnknownMaleSpecies' 11/17/15
    %folder = maleSpecies; %set a folder name in case no values match 6/4/15
    folder = 'UnknownMaleSpecies';
    allKeys = keys(folderMap);
    %also make a dictionary for the 'palli' names:
    strainMap = containers.Map();
    strainMap('pallidosa') = {'01','20001','"01"','"20001"','2001','".00"'};
    strainMap('pallidifrons') = {'PN175','pn175'};
    %check for palli first:
    inmalesp = strfind(maleSpecies, 'palli'); %also an option: 'palli '
    %if strcmp(maleSpecies,'palli') == 1 %replaced previous line 6/4/15
    if length(inmalesp) > 0
        %if strain == '01' || strain == 20001 %figure out what column the strain is
        %if strcmp(strain,'"01"') == 1 || strcmp(strain, '20001') == 1 %replaced previous line 6/4/15
        if sum(ismember(strainMap('pallidosa'),strain)) > 0
            folder = {'pallidosa'};
        elseif sum(ismember(strainMap('pallidifrons'),strain)) > 0
            %strain == 'pn175'  %^^find out strain (see above)
            %OR switch else and if so less work
            folder = {'pallidifrons'};
        else
            %folder = 'unknown'; 
            %this will trigger an error... but no longer necessary with new folder
        end
    else
        for key = allKeys
            %currentValues = values(folderMap, {key});
            currentValues = values(folderMap, key); %replaced previous line 6/4/15

            for value = currentValues
                innerval = value{1}; %added 6/4/15
                %length(innerval);
                %if maleSpecies == value
                if length(innerval) == 1
                    if strcmp(maleSpecies,innerval) == 1 
                        folder = key;
                    end
                else %loop over all possible values, added 6/4/15
                    for ival = innerval
                        if strcmp(maleSpecies,ival) == 1 
                            folder = key;
                        end
                    end
                end
            end
        end
    end
    if strcmp(folder, 'UnknownMaleSpecies')
        fprintf('Problematic maleSpecies for %s: %s\n', datestr(DATETODAY, 'yyyy-mm-dd'), maleSpecies) %note that this is uncharacterized
    end
    folderName = char(folder);
end

function excelFileArr = findExcelFileArr()
    global SPREADSHEETPATH;
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    try
        dateToday3 = datestr(DATETODAY, DATEFORMAT3);
    catch MEdT3
        fprintf('Issue with dateToday3; DATETODAY: %s, DATEFORMAT3: %s\n',DATETODAY,DATEFORMAT3);
        rethrow(MEdT3)
    end
    downloads = dir(fullfile(SPREADSHEETPATH, EXCELNAMESCHEME));
    downloadedRecordings = {};
    for i = 1:length(downloads)
        %may need to modify other instances of findstr
        datein = strfind(downloads(i).name, dateToday);
        datein = [datein strfind(downloads(i).name, dateToday2)];
        %datein = [datein strfind(downloads(i).name, dateToday3)];
        %Require 'g' or 's' to precede dateToday3 (otherwise could get wrong date)
        datein = [datein strfind(downloads(i).name, strcat('s',dateToday3))];
        datein = [datein strfind(downloads(i).name, strcat('g',dateToday3))];
        if length(datein) > 0       
            downloadedRecordings = [downloadedRecordings; downloads(i).name];
        end
    end
    switch length(downloadedRecordings)
        case 0
            % no file
            error(['There is no Excel file with a name including ' ...
                dateToday ' or ' dateToday2 ' in ' fullfile(SPREADSHEETPATH, EXCELNAMESCHEME) ...
                '. Please download the spreadsheet for this day.']);
        case 1
            % go for it
            excelfilename = [SPREADSHEETPATH downloadedRecordings{1}];
            excelFileArr = {excelfilename};
        case 2
            % save both filenames
            file1 = [SPREADSHEETPATH downloadedRecordings{1}];
            file2 = [SPREADSHEETPATH downloadedRecordings{2}];
            excelFileArr = {file1 file2};
            excelFileArr = sort(excelFileArr); 
        otherwise
            % multiple files
            error(['There are more than two Excel files with a name including ' ...
                dateToday '. Please download only one to two at a time.']);
    end
end

function folderMap = getfolderMap()
    % Create folderMap to point each species recording channel to a
    % specific path.
    % Optional: Load in folderMap from a file.
    global FOLDERMAPFILE;
    if exist(FOLDERMAPFILE, 'file') == 2
        fprintf('Loading %s from %s\n',FOLDERMAPFILE,pwd)
        load(FOLDERMAPFILE);
    else
        folderMap = containers.Map();
        folderMap('albomicans') = {'albomicans', 'alb', 'D. albomicans'};
        folderMap('americana') = {'americana', 'ameri'};
        folderMap('ananassae') = {'ananassae', 'ana'};
        %folderMap('athabasca5') = {'athabasca x5 (F1)'};
        %folderMap('athabasca13') = {'athabasca x13 (F1)'};
        %folderMap('athabasca16') = {'athabasca x16 (F1)'};
        folderMap('Cross1') = {'x1','A1','A1a','A1b'};
        folderMap('Cross2') = {'x2','A2','A2a','A2b'};
        folderMap('Cross3') = {'x3','A3','A3a','A3b'};
        folderMap('Cross4') = {'x4','A4','A4a','A4b'};
        folderMap('Cross5') = {'x5','A5','A5a','A5b','F1 (s. albostrigata/s. neonasuta)',...
                               'F1 (s. neonasuta/s. albostrigata)','F1 (s. neonasuta/s. albomicans)'};
        folderMap('Cross6') = {'x6','A6','A6a','A6b'};
        folderMap('Cross7') = {'x7','A7','A7a','A7b'};
        folderMap('Cross8') = {'x8','A8','A8a','A8b','Cross8'};
        folderMap('Cross9') = {'x9','x9 or albomicans'};
        x10arr = {'x10','A10','A10a','A10b'};
        for i = 1:100
            x10arr{length(x10arr)+1} = strcat('FC', num2str(i));
        end
        %folderMap('Cross10') = {'x10','A10','A10a','A10b'};
        folderMap('Cross10') = x10arr;
        folderMap('Cross11') = {'x11'};
        folderMap('Cross12') = {'x12'};
        folderMap('Cross13') = {'x13','A13','A13a','A13b'};
        folderMap('Cross14') = {'x14','A14','A14a','A14b'};
        folderMap('Cross16') = {'x16'}; %Determine how to include 'neonas/x16'... replace / before saving.
        folderMap('Cross17') = {'x17', 'F1 (nasuta/kepuluana)'};
        folderMap('Cross18') = {'x18','A18','A18a','A18b','A18 or s. sulfurigaster'};
        folderMap('Cross20') = {'x20','A20','A20a','A20b'};
        folderMap('Cross21') = {'x21', 'x21?'};
        folderMap('Cross22') = {'x22'};
        folderMap('kepuluana') = {'kepuluana', 'kep', 'Kep'};
        folderMap('kohkoa') = {'kohkoa', 'koh', 'D. kohkoa', 'Kohkoa', 'koh .01'};
        folderMap('nasuta') = {'nasuta', 'nas', 'D. nasuta'};
        folderMap('novomexicana') = {'novomexicana', 'novo', 'Novo'};
        folderMap('pallidifrons') = {'pallidifrons', 'D. pallidifrons'};
        %palli if strain is pn175
        folderMap('pallidosa') = {'pallidosa'};
        %palli if with x10 and strain is 20001 or '01' (i think)
        folderMap('pulaua') = {'pulaua', 'pul', 'pulau', 'pul.'};
        folderMap('salb') = {'s alb', 's. alb', 's albostrigata', ...
            's. albostrigata','s alb. ','s alb.', 's. albomicans', 's.albos'};
        folderMap('sbilim') = {'s bilim', 's. bilim', 's. bilimbata', 's bilimbata', ...
                               'bilim', 's. bil', 's bil', 's.bilim','s.bilimbata'};
        folderMap('sneonasuta') = {'s neonasuta', 's. neonasuta', 's neonas', ...
                                   's. neonas', 'neonas', 'neo nas', 'neo. nas'};
        folderMap('ssulf') = {'s sulf', 's. sulf', 'sulf', 's. sulfurigaster', ...
                              's sulfurigaster', 's. sulf .02'};
        folderMap('TaxonF') = {'TaxonF', 'Taxon F', 'D. Taxon F'};
        folderMap('TaxonG') = {'TaxonG', 'Taxon G', 'D. Taxon G'};
        folderMap('TaxonI') = {'TaxonI', 'Taxon I', 'D. Taxon I'};
        folderMap('TaxonJ') = {'TaxonJ', 'Taxon J', 'D. Taxon J'};
        folderMap('virilis') = {'virilis', 'virilis.', 'Virilis'};
        folderMap('lummei') = {'lummei'};
        folderMap('athabasca') = {'athabasca','athabasca x13 (F1)', 'athabasca x 16 (F1)', ...
                                  'athabasca x5 (F1)'};
        folderMap('melanogaster') = {'D. melanogaster', 'melanogaster', 'mel'};
        fprintf('Saving %s in %s\n',FOLDERMAPFILE,pwd)
        save(FOLDERMAPFILE,'folderMap');
    end
end

function verifyPath(folderPath, i)
    global EXCLUDECHANNELS;
    if ismember(i, EXCLUDECHANNELS)
        return;
    end
    global FEEDBACK;
    switch exist(folderPath, 'dir')
        case 0
            % A folder for this species does not exist.
            FEEDBACK = [FEEDBACK; ['ERROR: The folder ' folderPath ' does not exist.']];
            FEEDBACK = [FEEDBACK; ['ERROR: Create ' folderPath ' and run script again.']];
            FEEDBACK = [FEEDBACK; ['ERROR: No files were saved!!!']];
            disp(FEEDBACK);
            disp(folderPath);
            error('There was an error. See feedback above.');
        case 7
            % The folder exists! Continue.
        otherwise
            % Unknown conflict with path name for this species.
            FEEDBACK = [FEEDBACK; ['WARNING: The folder path ' folderPath ' caused an unknown problem. Files for this species may not be saved!!!']];
    end
end
