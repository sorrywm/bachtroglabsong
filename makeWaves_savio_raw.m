function makeWaves_savio_raw(dateArg)
    % default dateArg format: mmddyyyy
    % To do: Allow a and b spreadsheets to specify earlier and later
    % recordings for the same date.
    % To do: Sort athabasca by species/cross based on strain
    %        (possibly similar to 'palli')
    
    % First, make sure variables are not initialized from previous MATLAB instance.
    %possibly helpful: clear, who
    clearvars -except dateArg

    % Define some global variables
    global NUMCHANNELS;
    global EXCLUDECHANNELS;
    global FEEDBACK; % Save notices, warnings, and errors here.
    global RECORDINGSPATH; % Where to find BIG recording file.
    global RECORDINGNAMESCHEME; % Search criteria for recording folder.
    global BINFILENAMESCHEME; % Search criteria for .bin file.
    global BINFUNCTIONSPATH; % Path to functions for working with .bin files.
    global SPREADSHEETPATH; % Where the Excel file is downloaded.
    global EXCELNAMESCHEME; % Search criteria for Excel file.
    global SAVETOPATH; % Where individual channel files are saved.
    global DATEFORMAT; % Date format used in Excel filename.
    global DATEFORMAT2; % New: second format used in Excel filename.
    global DATEFORMAT3; % New: third format used in Excel filename.
    global DATETODAY;
    global SPF; % SamplesPerFrame (or number of bytes to read at a time from .wav file)
    global BUTTERDIR; % Location of various MATLAB files with useful functions
    global FOLDERMAPFILE; %new: filename for folderMap
    global SAVEFILT; %new: whether to save raw or filtered files, or both 
                     %(options: raw, filt, both)
    global FILTCUT; %new: cutoff for high-pass filter
    global AB; %new: whether a spreadsheet is 'a' or 'b' 
               %(or '', if only one spreadsheet)

    % Optional: load these variables from a file ('dateArg'.opts.mat).
    % File must be in MATLAB's path.
    % Important: move/delete older file before re-running the same date.
    optsfile = strcat('optsfiles/',dateArg,'.opts.mat');
    if exist(optsfile, 'file') == 2
        load(optsfile);
        %disp(DATETODAY)
    else
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
        FOLDERMAPFILE = 'folderMap.mat'; %save in same directory with script
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
                    DATETODAY = datenum(dateArg, 'mmddyy');
                case 8
                    DATETODAY = datenum(dateArg, 'mmddyyyy');
                case 10
                    DATETODAY = datenum(dateArg, 'yyyy-mm-dd')
                otherwise
                    error('Issue with dateArg: %s', dateArg)
            end
    end
    
    addpath(BUTTERDIR);
    addpath(BINFUNCTIONSPATH);
    dateToday = datestr(DATETODAY, DATEFORMAT); 
    Channels = cell(NUMCHANNELS,1);
    Extracted = cell(NUMCHANNELS,1);
    Filtered = cell(NUMCHANNELS,1);
    FilenameNotes = cell(NUMCHANNELS,1);
    for i = 1:32
        Channels{i} = ['Channel ' num2str(i)];
    end
    
    timeStart = datetime('now');
    tic;
    
    % Load or generate folderMap.
    folderMap = getfolderMap();
    %disp(DATETODAY)
    % Find a recording spreadsheet corresponding to today's date.
    % If there are two recordings, there may be "a" and "b" files.
    % Option: have findExcelFile return an array. If the array is
    % length 2, loop over the remaining code.
    % Save whether the spreadsheet is "a" or "b" for use in 
    % determining which .bin/.wav file to use.
    
    %excelFile = findExcelFile();
    
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
                        firstrowmsg = ['Issue with dateRaw for ',dateArg,': ', num2str(dateRaw), ', class: ', class(dateRaw)]
                    else
                        firstrowmsg = ['Issue with dateRaw for ',dateArg,': ', dateRaw, ', class: ', class(dateRaw)]
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

            %maleSpecies = txt{i, 12}; %always column 12
            %maleStrain = txt{i, 13}; %added 6/4/15
            %femaleSpecies = txt{i, 6}; %replaced previous row 6/4/15
            %femaleStrain = txt{i, 7}; %added 8/8/15
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
            if strcmp(fileName, fileNameCleaned) ~= 1
                FilenameNotes{i} = 'Changed at least one character';
            else
                FilenameNotes{i} = 'No changes';
            end
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
        timetoreadexcel = toc;
        
        % Check to make sure the dates are right before proceeding
        ssdatestring = datestr(DATETODAY,'yyyy-mm-dd');
        [rightDate, wrongRow] = checkSpreadsheetDate(ssdatestring, raw, setdiff([1:NUMCHANNELS],EXCLUDECHANNELS));
        if rightDate == 0
            wrongDate = raw{wrongRow,1};
            if isnumeric(raw{wrongRow,1});
                wrongDate = datestr(raw{wrongRow,1},'yyyy-mm-dd');
            end
            error('The spreadsheet for %s has the wrong date in row %i: %s.\n',ssdatestring,wrongRow,wrongDate)
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
            FEEDBACK = [FEEDBACK; ['All of the ' num2str(NUMCHANNELS-length(EXCLUDECHANNELS)) ...
                                   ' specified files for ' datestr(DATETODAY, 'yyyy-mm-dd') AB{f} ...
                                   ' already exist. Nothing to do.']];
            FEEDBACK
            %filePathsNoExt{1}
            continue;
        end

        % Find the .wav file corresponding to today's date.
        wavFile = findWavFileExt(AB{f});
        if strcmp(wavFile,'findbin')
            % Find the .bin file corresponding to today's date.
            % Modified to allow the case in which 
            % the recording is one of two (a or b).
            %binFileNoExt = findBinFile();
            binFileNoExt = findBinFileExt(AB{f});
            wavFile = [binFileNoExt '.wav'];
        end
       
        %Check that .wav/.bin file was created on the right date.
        wavdate = datestr(DATETODAY,'yyyymmdd');
        rightWavDate = checkWavDate(wavdate,wavFile);
        if rightWavDate == 0
            error('.wav file %s was not created on %s.\n',wavFile,wavdate)
        end
 
        disp('Looking for .bin and .wav files...');
        switch exist(wavFile, 'file')
            case 0
                % The .wav file does not exist. Attempt to convert the .bin file.
                disp('Converting .bin file to .wav file. This may take a few minutes.');
                tic;
                try
                    bin2wav(binFileNoExt);
                catch MEb2w
                    error('Issue converting bin file %s./n',binFileNoExt)
                end
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
        %audiodata = zeros(info.TotalSamples, NUMCHANNELS);
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
        timetoreadbigwav = toc;

        % Suppress warning message about clipping data.
        % Almost every file has data clipped.
        warning('off','MATLAB:audiovideo:audiowrite:dataClipped');
        tic;

        %New: Check that number of non-excluded channels in the spreadsheet
        %     is </= the number of channels in the .wav file. If not, this
        %     part may not run.
        spreadsheetchannels = NUMCHANNELS - length(EXCLUDECHANNELS);
        wavchannels = info.NumChannels;
        if spreadsheetchannels > wavchannels
            if wavchannels == 1
                %Write an error message and exit
                error(['There are more non-excluded channels in the spreadsheet ('...
                        num2str(spreadsheetchannels) ') than in the .wav file for ' dateToday '('...
                        num2str(wavchannels) '). Please check the files.']) 
            else
                %Write 'Warning:' to .o file and don't exit.
                warning(['There are more non-excluded channels in the spreadsheet ('...
                          num2str(spreadsheetchannels) ') than in the .wav file for ' dateToday '('...
                          num2str(wavchannels) '). Extracting first ' num2str(wavchannels) ' only.'])
                NUMCHANNELS = wavchannels;
            end
        end
        %else
        for i = 1:NUMCHANNELS
            % First check if this channel should be excluded.
            exclude = 0;
            for x = 1:length(EXCLUDECHANNELS)
                if i == EXCLUDECHANNELS(x)
                    exclude = 1;
                end
            end
            pct = (100 * i / NUMCHANNELS);
            pct = num2str(pct, '%02f');
            pct = pct(1:5);
            pct = [pct '%'];
            disp(['Writing individual channel .wav files ... ' pct]);
            switch exclude
                case 0 % This channel is not specifically excluded.
                       % Determine whether raw or filtered files (or both)
                       % should be saved.
                       % Write a raw .wav file.
                    [Extracted{i}, Filtered{i}] = saveChannel(filePathsNoExt{i}, SAVEFILT, audiodata, i, h.SampleRate, FILTCUT);
                case 1 % This channel is specifically excluded.
                       % Skip this channel.
                    Extracted{i} = 'Specifically Excluded'; % Note that channel i was extracted.
                    Filtered{i} = 'Specifically Excluded'; % Note that channel i was extracted.
                otherwise
                   error('Issue with exclude rule: %d./n',exclude)
            end
        end
        % Restore status of warning message about clipping data.
        % ...in case other scripts need it to be on.
        warning('on','MATLAB:audiovideo:audiowrite:dataClipped');
        timetowritechannels = toc;
        timeEnd = datetime('now');
        disp('Total time:');
        disp(timeEnd - timeStart);
        FEEDBACK
        t = table(Channels, Extracted, Filtered, FilenameNotes);
        disp(['Summary for ' datestr(DATETODAY, 'yyyy-mm-dd')]);
        disp(t);
    end
end

function excelFile = findExcelFile()
    %also add DATEFORMAT3: 'mmddyy' (some Excel files are saved with these names)
    global SPREADSHEETPATH;
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    dateToday3 = datestr(DATETODAY, DATEFORMAT3);
    downloads = dir(fullfile(SPREADSHEETPATH, EXCELNAMESCHEME));
    downloadedRecordings = {};
    for i = 1:length(downloads)
        datein = strfind(downloads(i).name, dateToday);
        datein = [datein strfind(downloads(i).name, dateToday2)];
        %Require 'g' or 's' to precede dateToday3 (otherwise could get wrong date)
        datein = [datein strfind(downloads(i).name, strcat('s',dateToday3))];
        datein = [datein strfind(downloads(i).name, strcat('g',dateToday3))];
        if length(datein) > 0
            downloadedRecordings = [downloadedRecordings; downloads(i).name]
        end
    end
    switch length(downloadedRecordings)
        case 0
            % no file
            error(['There is no Excel file with a name including ' ...
                dateToday '(dateArg: ' dateArg '). Please download the spreadsheet for today.']);
        case 1
            % go for it
            excelFile = [SPREADSHEETPATH downloadedRecordings{1}];
        otherwise
            % multiple files
            error(['There are multiple Excel files with a name including ' ...
                dateToday '(dateArg: ' dateArg '). Please download only one at a time.']);
    end
end


function excelFileArr = findExcelFileArr()
%now saving to its own file
    global SPREADSHEETPATH;
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    %disp(DATETODAY)
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


function remakeWaves()
    % Scans through the RECORDINGSPATH folder looking folders with
    % RECORDINGNAMESCHEME. Extracts the date portion of each folder name,
    % and passes that date to makeWaves().
    global RECORDINGSPATH;
    global RECORDINGNAMESCHEME;
    recordings = dir(fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME));
    for i = 1:length(recordings)
        makeWaves(strrep(recordings(i).name,'Recordings',''));
    end
end


function binFile = findBinFile()
    global RECORDINGSPATH;
    global RECORDINGNAMESCHEME;
    global BINFILENAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    recordings = dir(fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME));
    recordingFolders = {};
    for i = 1:length(recordings)
        dateinrec = strfind(recordings(i).name, dateToday);
        dateinrec = [dateinrec strfind(recordings(i).name, dateToday2)];
        if length(dateinrec) > 0
            recordingFolders = [recordingFolders; recordings(i).name];
        end
    end
    switch length(recordingFolders)
        case 0
            % no folder
            error(['There is no recording folder with a name including ' ...
                dateToday ' or ' dateToday2 '. Verify that a recording ' ...
                'was completed today and it is saved in the correct folder.']);
        case 1
            % go for it
            binFilePath = [RECORDINGSPATH recordingFolders{1} '/'];
            recordingFiles = dir(fullfile(binFilePath, BINFILENAMESCHEME));
            switch length(recordingFiles)
                case 0
                    % no bin file
                    disp(RECORDINGSPATH);
                    disp(recordingFolders{1});
                    error(['There is no .bin file in the recording folder. ' ...
                        'Make sure the recording was successful and try again.']);
                case 1
                    % go for it
                    binFile = [binFilePath recordingFiles(1).name];
                    binFile = strrep(binFile, '.bin', '');
                %case 2
                    %return an array with the sorted .bin names.
                    %binFile1 = [binFilePath recordingFiles(1).name];
                    %binFile2 = [binFilePath recordingFiles(2).name];
                    %binFile = {binFile1 binFile2}
                otherwise
                    % multiple .bin files
                    error(['There are multiple .bin files in the recording folder. ' ...
                        'Please move or rename all but one and try again.']);
            end
        otherwise
            % multiple folders
            error(['There are multiple folders with a name including ' ...
                dateToday '. Please move or rename all but one and try again.']);
    end
end

function wavFile = findWavFileExt(ab)
    global RECORDINGSPATH;
    global RECORDINGNAMESCHEME;
    global BINFILENAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    recordings = dir(fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME));
    recordingFolders = {};
    for i = 1:length(recordings)
        dateinrec = strfind(recordings(i).name, dateToday);
        dateinrec = [dateinrec strfind(recordings(i).name, dateToday2)];
        if length(dateinrec) > 0
            recordingFolders = [recordingFolders; recordings(i).name];
        end
    end
    recordingFolders = sort(recordingFolders);
    switch length(recordingFolders)
        case 0
            % no folder
            error(['There is no recording folder with a name including ' ...
                dateToday ' or ' dateToday2 ' in ' fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME) ...
                '. Verify that a recording was completed this day and ' ...
                'it is saved in the correct folder.']);
        case 1
            % go for it
            wavFilePath = [RECORDINGSPATH recordingFolders{1} '/'];
            recordingFiles = dir(fullfile(wavFilePath, '*.wav'));
            switch length(recordingFiles)
                case 0
                    % no wav file.... Look for bin file!
                    wavFile = 'findbin';
                case 1
                    % go for it
                    wavFile = [wavFilePath recordingFiles(1).name];
                case 2
                    % get the right file based on a/b
                    if strcmp(ab, 'a')
                        wavFile = [wavFilePath recordingFiles(1).name];
                    elseif strcmp(ab, 'b')
                        wavFile = [binFilePath recordingFiles(2).name];
                    elseif strcmp(ab, '')
                        recordingFiles(1).name
                        recordingFiles(2).name
                        error(['There are two .wav files in the recording folder' ...
                            ', but there is only one spreadsheet for ' dateToday ...
                            '. Please move or rename the extra .wav file and try again.']);
                    else
                        error(['Issue specifying a/b for ' dateToday ':' ab]);
                    end
                otherwise
                    % multiple .wav files.... Check for .bin file!
                    wavFile = 'findbin';
            end
        otherwise
            % multiple folders
            error(['There are multiple folders with a name including ' ...
                dateToday '. Please move or rename all but one and try again.']);
    end
end

function binFile = findBinFileExt(ab)
    global RECORDINGSPATH;
    global RECORDINGNAMESCHEME;
    global BINFILENAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    recordings = dir(fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME));
    recordingFolders = {};
    for i = 1:length(recordings)
        dateinrec = strfind(recordings(i).name, dateToday);
        dateinrec = [dateinrec strfind(recordings(i).name, dateToday2)];
        if length(dateinrec) > 0
            recordingFolders = [recordingFolders; recordings(i).name];
        end
    end
    recordingFolders = sort(recordingFolders);
    switch length(recordingFolders)
        case 0
            % no folder
            error(['There is no recording folder with a name including ' ...
                dateToday ' or ' dateToday2 ' in ' fullfile(RECORDINGSPATH, RECORDINGNAMESCHEME) ...
                '. Verify that a recording was completed this day and ' ...
                'it is saved in the correct folder.']);
        case 1
            % go for it
            binFilePath = [RECORDINGSPATH recordingFolders{1} '/'];
            recordingFiles = dir(fullfile(binFilePath, BINFILENAMESCHEME));
            switch length(recordingFiles)
                case 0
                    % no bin file
                    disp(RECORDINGSPATH);
                    disp(recordingFolders{1});
                    error(['There is no .bin file in the recording folder. ' ...
                        'Make sure the recording was successful and try again.']);
                case 1
                    % go for it
                    binFile = [binFilePath recordingFiles(1).name];
                    binFile = strrep(binFile, '.bin', '');
                case 2
                    % get the right file based on a/b
                    if strcmp(ab, 'a')
                        binFile = [binFilePath recordingFiles(1).name];
                        binFile = strrep(binFile, '.bin', '');
                    elseif strcmp(ab, 'b')
                        binFile = [binFilePath recordingFiles(2).name];
                        binFile = strrep(binFile, '.bin', '');
                    elseif strcmp(ab, '')
                        recordingFiles(1).name
                        recordingFiles(2).name
                        error(['There are two .bin files in the recording folder' ...
                            ', but there is only one spreadsheet for ' dateToday ...
                            '. Please move or rename the extra .bin file and try again.']);
                    else
                        error(['Issue specifying a/b for ' dateToday ':' ab]);
                    end
                otherwise
                    % multiple .bin files
                    error(['There are multiple .bin files in the recording folder for ' dateToday ...
                           '. Please move or rename all but one and try again.']);
            end
        otherwise
            % multiple folders
            error(['There are multiple folders with a name including ' ...
                dateToday '. Please move or rename all but one and try again.']);
    end
end


function folderName = findFolder(folderMap, maleSpecies, strain) %added strain and specified output as fullDir 6/4/15
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
        if strcmp(maleSpecies, 'pallidosa')
            folder = {'pallidosa'};
        elseif strcmp(maleSpecies, 'pallidifrons')
            folder = {'pallidifrons'};
        %if strain == '01' || strain == 20001 %figure out what column the strain is
        %if strcmp(strain,'"01"') == 1 || strcmp(strain, '20001') == 1 %replaced previous line 6/4/15
        elseif sum(ismember(strainMap('pallidosa'),strain)) > 0
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

        %fullDir = strcat(folderDir, folder); moved outside for loop 6/4/15
    end
    if strcmp(folder, 'UnknownMaleSpecies')
        fprintf('Problematic maleSpecies: %s; strain: %s\n', maleSpecies, strain) %note that this is uncharacterized
    end
    folderName = char(folder);
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
        folderMap('Cross4') = {'x4','A4','A4a','A4b','F1 (s. sulfurigaster/s. albostrigata'};
        folderMap('Cross5') = {'x5','A5','A5a','A5b','F1 (s. albostrigata/s. neonasuta)',...
                               'F1 (s. neonasuta/s. albostrigata)','F1 (s. neonasuta/s. albomicans)'};
        folderMap('Cross6') = {'x6','A6','A6a','A6b','F1 (s. bilimbata/s. neonasuta)'};
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

function [extracted, filtered] = saveChannel(filePath, savefilt, audiodata, channel, samplerate, filtcut)
%[Extracted{i}, Filtered{i}] = saveChannel(filePathsNoExt{i}, SAVEFILT, audiodata, i, h.SampleRate, FILTCUT);
    extracted = [];
    filtered = [];
    if strcmp(savefilt, 'raw') | strcmp(savefilt, 'both')
        filePathRaw = [char(filePath) '-raw.wav'];
        switch exist(filePathRaw, 'file') % Determine if a file for this channel already exists.
            case 0 % The file does not exist; create it.
                audiowrite(filePathRaw, audiodata(:,channel), 6000); % Write channel i to a .wav file.
                extracted = 'Yes'; % Note that channel i was extracted.
            case 2 % The file already exists.
                extracted = 'Previously extracted'; % Note that channel i was extracted.
            otherwise
                error('Issue with type of file: %s./n', filePathRaw)
        end
    end
    % Filter out 200 Hz.
    if strcmp(savefilt, 'filt') || strcmp(savefilt, 'both')
        filePath200 = [char(filePath) '-filt' num2str(filtcut) '.wav'];
        switch exist(filePath200, 'file') % Determine if a file for this channel already exists.
            case 0 % The file does not exist; create it.
                filt200 = tybutter(audiodata(:,channel), filtcut, samplerate, 'high');
                % Then write to a new file.
                audiowrite(filePath200, filt200, 6000);
                filtered = 'Yes'; % Note that channel i was extracted.
            case 2 % The file already exists.
                filtered = 'Previously filtered'; % Note that channel i was extracted.
            otherwise
                error('Issue with type of file: %s./n', filePath200)
        end
    end
end
