function dorename = wavNaming_matt(excelFile, wavFile, errorFile, outFile) % (?????)
    %This assumes the folders in folderMap below have been created as
    %subdirectories in the following folder:
    %folderDir = 'J:\SoundData\NewPerSpeciesRecordingsMono\';
    
    % Track time to complete processing
    t0 = datetime('now');

    %added ellipses (...) 6/4/15
    %(http://www.mathworks.com/help/matlab/matlab_prog/continue-long-statements-on-multiple-lines.html)
    %save a variable keeping track of whether there were naming issues
    dorename = 0;
    %folderDir = 'J:\SoundData\PerSpeciesRecordingsMono\'; 
    %moved within findFolder 6/4/15
    xlRange = 'A1:R34'; %added 6/4/15
    %[num, txt, raw, custom] = xlsread(excelFile, 'Sheet1',  xlRange, '', processFcn);
    [~, txt, ~] = xlsread(excelFile, 'Sheet1',  xlRange); %replaced previous row 6/4/15
    
    %errorout = fopen('J:/SoundData/ProblematicFilesFromwavNaming.txt','w');
    errorout = fopen(errorFile,'at');
    mainout = fopen(outFile,'at');
    %replace filename and sheet with the actual filenames that I want to get
    %and the correct sheet name, especially if trying to extract data from a
    %'Sheet1' ok for normal excel spreadsheet, but will need to be an input or 
    %changed to an input if looking at an excel spreadsheet that is a collection
    %of multiple days of data --> file with multiple sheets

    folderMap = containers.Map();
    folderMap('albomicans') = {'albomicans', 'alb'};
    folderMap('americana') = {'americana', 'ameri'};
    folderMap('ananassae') = {'ananassae', 'ana'};
    %folderMap('athabasca5') = {'athabasca x5 (F1)'};
    %folderMap('athabasca13') = {'athabasca x13 (F1)'};
    %folderMap('athabasca16') = {'athabasca x16 (F1)'};
    folderMap('Cross1') = {'x1','A1','A1a','A1b'};
    folderMap('Cross2') = {'x2','A2','A2a','A2b'};
    folderMap('Cross3') = {'x3','A3','A3a','A3b'};
    folderMap('Cross4') = {'x4','A4','A4a','A4b'};
    folderMap('Cross5') = {'x5','A5','A5a','A5b','F1 (s. albostrigata/s. neonasuta)'};
    folderMap('Cross6') = {'x6','A6','A6a','A6b'};
    folderMap('Cross7') = {'x7','A7','A7a','A7b'};
    folderMap('Cross8') = {'x8','A8','A8a','A8b','Cross8'};
    folderMap('Cross9') = {'x9','x9 or albomicans'};
    folderMap('Cross10') = {'x10','A10','A10a','A10b'};
    folderMap('Cross11') = {'x11'};
    folderMap('Cross12') = {'x12'};
    folderMap('Cross13') = {'x13','A13','A13a','A13b'};
    folderMap('Cross14') = {'x14','A14','A14a','A14b'};
    folderMap('Cross16') = {'x16'}; %Determine how to include 'neonas/x16'... replace / before saving.
    folderMap('Cross17') = {'x17'};
    folderMap('Cross18') = {'x18','A18','A18a','A18b','A18 or s. sulfurigaster'};
    folderMap('Cross20') = {'x20','A20','A20a','A20b'};
    folderMap('Cross21') = {'x21'};
    folderMap('Cross22') = {'x22'};
    folderMap('kepuluana') = {'kepuluana', 'kep', 'Kep'};
    folderMap('kohkoa') = {'kohkoa', 'koh', 'D. kohkoa', 'Kohkoa'};
    folderMap('nasuta') = {'nasuta', 'nas', 'D. nasuta'};
    folderMap('novomexicana') = {'novomexicana', 'novo'};
    folderMap('pallidifrons') = {'pallidifrons', 'D. pallidifrons'};
    %palli if strain is pn175
    folderMap('pallidosa') = {'pallidosa'};
    %palli if with x10 and strain is 20001 or '01' (i think)
    folderMap('pulaua') = {'pulaua', 'pul', 'pulau', 'pul.'};
    folderMap('salb') = {'s alb', 's. alb', 's albostrigata', ...
        's. albostrigata','s alb. ','s alb.', 's. albomicans'};
    folderMap('sbilim') = {'s bilim', 's. bilim', 's. bilimbata', 's bilimbata', ...
                           'bilim', 's. bil', 's bil', 's.bilim'};
    folderMap('sneonasuta') = {'s neonasuta', 's. neonasuta', 's neonas', ...
                               's. neonas', 'neonas', 'neo nas'};
    folderMap('ssulf') = {'s sulf', 's. sulf', 'sulf', 's. sulfurigaster', ...
                          's sulfurigaster'};
    folderMap('TaxonF') = {'TaxonF', 'Taxon F', 'D. Taxon F'};
    folderMap('TaxonG') = {'TaxonG', 'Taxon G', 'D. Taxon G'};
    folderMap('TaxonI') = {'TaxonI', 'Taxon I', 'D. Taxon I'};
    folderMap('TaxonJ') = {'TaxonJ', 'Taxon J', 'D. Taxon J'};
    folderMap('virilis') = {'virilis', 'virilis.'};
    folderMap('lummei') = {'lummei'};
    folderMap('athabasca') = {'athabasca'};

    %call all necessary functions and variables here
    %moved the next two rows within for loop 6/4/15
    %dateRaw = txt{row, 1};  %always column 1
    %convertDate(dateRaw) %should store dateString as a variable in MATLAB and 
    %use it later to make the fileName
    
    
    
    
    butterdir='D:\BackupFromDesktop072815\MATLABCode';  %changed!
    
    addpath(butterdir)
    %Extract one channel from a wavfile, apply filter, and save the data.
    if nargin < 1 || isempty(wavFile)
       wavFile='J:\SoundData\Recordings07292014\20140729T120920a.wav';
    end
    %Save if there is an issue with the number of channels
    errchan = 0;
    %Open the .wav file (only once before looping thru channels).
    info=audioinfo(wavFile);
    %Because files are large, data will need to be parsed a few bits at a time.
    %e.g.: http://www.mathworks.com/matlabcentral/newsreader/view_thread/302506
    % construct the object, set the filename equal to your .wav file
    % set the SamplesPerFrame property to your desired value
%%%%%%%%    h = dsp.AudioFileReader('Filename',wavFile,'SamplesPerFrame',1024); 
    h = dsp.AudioFileReader('Filename',wavFile,'SamplesPerFrame',524288); 
%%%%%%%%%%%%%% NOTE: Reading 1kb at a time is way too slow; reading
%%%%%%%%%%%%%% at 1MB at a time loads 2-3GB in about 1 minute!
    
%    audiodata = zeros(h.SamplesPerFrame,1);
%    audio = step(h);
%    audiodata = [audiodata; audio(:,1)];
%    disp(length(audiodata));
%    error('bye');
    
    
    filenames = {'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',''};
    
    %row3 = channel1
    % Populate filenames[] with filenames constructed from spreadsheet.
    for i = 1:31
        channelNumber = i;
        row = i+2;
        
        %moved the next two rows within for loop 6/4/15
        dateRaw = txt{row, 1};  %always column 1
        %modified the next row to save output as 'dateString' 6/4/15
        dateString = convertDate(dateRaw); %should store dateString as a variable in MATLAB and 
        %use it later to make the fileName
        
        maleSpecies = txt{row, 12}; %always column 12
        %femaleSpecies = {row, 6};  %always column 6 when read excel this way
        femaleSpecies = txt{row, 6}; %replaced previous row 6/4/15
        strain = txt{row, 13}; %added 6/4/15

        %fileName = ['Channel', channelNumber, '_', dateString, '_', maleSpecies, ...
        %            '_', femaleSpecies, 'female'];
        fileName = [dateString, '_', 'Channel', num2str(channelNumber), '_', maleSpecies, ...
                    '_', strain, '-male___', femaleSpecies, '-female.wav_data']; %replaced previous line 6/4/15
        %findFolder(folderMap, maleSpecies) 
        fullDir = findFolder(folderMap, maleSpecies, strain); %replaced previous line 6/4/15
        %fileNameAndPath = strcat(fullDir, fileName);
        try
            if ischar(fileName)
                fileName = regexprep(fileName, ...
                '[^\d\w~!@#$%^&()_\-{}.]*','');
                fileNameAndPath = strcat(fullDir, '\', fileName);
                %Attempt to remove problematic characters.
                %From http://www.mathworks.com/matlabcentral/newsreader/view_thread/49594
                %fileNameAndPath = regexprep(fileNameAndPath, ...
                %'[^\d\w~!@#$%^&()_\-{}.]*','');
            else
                fileName = regexprep(fileName, ...
                '[^\d\w~!@#$%^&()_\-{}.]*','');
                fileNameAndPath = strcat(fullDir, '\', strjoin(fileName,'')); %replaced previous line 6/4/15
                %fileNameAndPath = regexprep(fileNameAndPath, ...
                %'[^\d\w~!@#$%^&()_\-{}.]*','');
            end
        catch ME
            fileName
            class(fileName)
            ME.identifier
            rethrow(ME)
            exit
        end
            %call ExtractSingleChannelsFromWAV with wavFile, channelNumber, and
    %fileNameAndPath
        if iscell(fileNameAndPath)
            if exist(fullDir{1}) ~= 7
                fprintf(errorout, 'No folder %s.\n',...
                        fileNameAndPath{1});
                dorename = 1;
                continue
            end
            if exist(strcat(fileNameAndPath{1},'.mat'),'file') ~= 2
                %Only write if file doesn't already exist.
                tic;
                fprintf(mainout,'Getting channel %s from %s at %s.\n', num2str(channelNumber),wavFile,datestr(now));
                filenames{i} = fileNameAndPath{1};
%%%%%%                notrec = ExtractSingleChannelsFromWAV_matt(wavFile, channelNumber, fileNameAndPath{1});



        
                if channelNumber > info.NumChannels
                    fprintf(errorout, 'No recording for %s.\n',...
                        fileNameAndPath{1});
                    dorename = 2; %trigger continue in GetWavData
                    break
                end

                
                
                

                fprintf(mainout,'Saved file: %s.\n',...
                    fileNameAndPath{1});
                %toc;
                etime = toc;
                fprintf(mainout,'Elapsed time is %s seconds.\n',...
                    num2str(etime));
            end
        else
            %seems to be a char when male or female species 
            %is not in folderMap
            %Maybe write the non-NA/missing ones to a new file?
            if strcmp(maleSpecies,'NA')~=1 && strcmp(maleSpecies,'')~=1
                fprintf(errorout,'Name not in folderMap: %s\n',...
                    fileNameAndPath);
                dorename = 1;
            end
        end
        %need to give the full path above?
    %later, to make it more efficient, modify extract code to get all 32
    %channels at once and then name and save all of them in the
    %approprpiate places with a vector of all the names in the right order
    %to correspond to the channels
    %when modifying the code, possibly add an input that specifies to
    %skip over channels that were not used so that it doesn't waste time
    %^^double check that this would also be added into the naming file as well
    end

%%%%%% done generating filenames[] array with all .wav filenames that will be created next.    
    
    
    % add a for loop to repeat the following for each channel (what is kept in
    % memory?)
    % just initialize a vector of zeros to carry the first empty frame--we'll get rid of this
    audiodata1 = zeros(h.SamplesPerFrame,1);
    audiodata2 = zeros(h.SamplesPerFrame,1);
    audiodata3 = zeros(h.SamplesPerFrame,1);
    audiodata4 = zeros(h.SamplesPerFrame,1);
    audiodata5 = zeros(h.SamplesPerFrame,1);
    audiodata6 = zeros(h.SamplesPerFrame,1);
    audiodata7 = zeros(h.SamplesPerFrame,1);
    audiodata8 = zeros(h.SamplesPerFrame,1);
    audiodata9 = zeros(h.SamplesPerFrame,1);
    audiodata10 = zeros(h.SamplesPerFrame,1);
    audiodata11 = zeros(h.SamplesPerFrame,1);
    audiodata12 = zeros(h.SamplesPerFrame,1);
    audiodata13 = zeros(h.SamplesPerFrame,1);
    audiodata14 = zeros(h.SamplesPerFrame,1);
    audiodata15 = zeros(h.SamplesPerFrame,1);
    audiodata16 = zeros(h.SamplesPerFrame,1);
    audiodata17 = zeros(h.SamplesPerFrame,1);
    audiodata18 = zeros(h.SamplesPerFrame,1);
    audiodata19 = zeros(h.SamplesPerFrame,1);
    audiodata20 = zeros(h.SamplesPerFrame,1);
    audiodata21 = zeros(h.SamplesPerFrame,1);
    audiodata22 = zeros(h.SamplesPerFrame,1);
    audiodata23 = zeros(h.SamplesPerFrame,1);
    audiodata24 = zeros(h.SamplesPerFrame,1);
    audiodata25 = zeros(h.SamplesPerFrame,1);
    audiodata26 = zeros(h.SamplesPerFrame,1);
    audiodata27 = zeros(h.SamplesPerFrame,1);
    audiodata28 = zeros(h.SamplesPerFrame,1);
    audiodata29 = zeros(h.SamplesPerFrame,1);
    audiodata30 = zeros(h.SamplesPerFrame,1);
    audiodata31 = zeros(h.SamplesPerFrame,1);
%    audiodata32 = zeros(h.SamplesPerFrame,1);
    %Try to troubleshoot so it doesn't require too much memory.
    %initialize a vector of zeros for the whole file
    %audiodata = zeros(info.TotalSamples);
    %wind = 1:h.SamplesPerFrame;
    % start the while loop to read in the two-channel audio frame by frame
    %tic;        
    while ~isDone(h)
        try
            % read the audio frame (1024 samples)
            audio = step(h);
            % just keep one channel
            audiodata1 = [audiodata1; audio(:,1)];
            audiodata2 = [audiodata2; audio(:,2)];
            audiodata3 = [audiodata3; audio(:,3)];
            audiodata4 = [audiodata4; audio(:,4)];
            audiodata5 = [audiodata5; audio(:,5)];
            audiodata6 = [audiodata6; audio(:,6)];
            audiodata7 = [audiodata7; audio(:,7)];
            audiodata8 = [audiodata8; audio(:,8)];
            audiodata9 = [audiodata9; audio(:,9)];
            audiodata10 = [audiodata10; audio(:,10)];
            audiodata11 = [audiodata11; audio(:,11)];
            audiodata12 = [audiodata12; audio(:,12)];
            audiodata13 = [audiodata13; audio(:,13)];
            audiodata14 = [audiodata14; audio(:,14)];
            audiodata15 = [audiodata15; audio(:,15)];
            audiodata16 = [audiodata16; audio(:,16)];
            audiodata17 = [audiodata17; audio(:,17)];
            audiodata18 = [audiodata18; audio(:,18)];
            audiodata19 = [audiodata19; audio(:,19)];
            audiodata20 = [audiodata20; audio(:,20)];
            audiodata21 = [audiodata21; audio(:,21)];
            audiodata22 = [audiodata22; audio(:,22)];
            audiodata23 = [audiodata23; audio(:,23)];
            audiodata24 = [audiodata24; audio(:,24)];
            audiodata25 = [audiodata25; audio(:,25)];
            audiodata26 = [audiodata26; audio(:,26)];
            audiodata27 = [audiodata27; audio(:,27)];
            audiodata28 = [audiodata28; audio(:,28)];
            audiodata29 = [audiodata29; audio(:,29)];
            audiodata30 = [audiodata30; audio(:,30)];
            audiodata31 = [audiodata31; audio(:,31)];
%            audiodata32 = [audiodata32; audio(:,32)];
%%%%%%%            disp(100*length(audiodata)/23100000);
            %audiodata(wind) = audio(:,channelNumber);
            %wind = wind + h.SamplesPerFrame;
        catch ME
            if (strcmp(ME.identifier,'dspshared:system:libOutFromMmFile'))
                %"the audio input stream has become unresponsive"
%%%%% this is now probably an uninformative error message.                
                fprintf(errorout, 'Issue with audio input stream for %s.\n',...
                    fileNameAndPath{1});
                %error('Issue with input stream for channel %s\n',channelNumber)
                continue
            else
                wavFile
                ME.identifier
                rethrow(ME)
            end            
        end
    end
    % get rid of the zeros at the beginning
    audiodata1(1:h.SamplesPerFrame) = [];
    audiodata2(1:h.SamplesPerFrame) = [];
    audiodata3(1:h.SamplesPerFrame) = [];
    audiodata4(1:h.SamplesPerFrame) = [];
    audiodata5(1:h.SamplesPerFrame) = [];
    audiodata6(1:h.SamplesPerFrame) = [];
    audiodata7(1:h.SamplesPerFrame) = [];
    audiodata8(1:h.SamplesPerFrame) = [];
    audiodata9(1:h.SamplesPerFrame) = [];
    audiodata10(1:h.SamplesPerFrame) = [];
    audiodata11(1:h.SamplesPerFrame) = [];
    audiodata12(1:h.SamplesPerFrame) = [];
    audiodata13(1:h.SamplesPerFrame) = [];
    audiodata14(1:h.SamplesPerFrame) = [];
    audiodata15(1:h.SamplesPerFrame) = [];
    audiodata16(1:h.SamplesPerFrame) = [];
    audiodata17(1:h.SamplesPerFrame) = [];
    audiodata18(1:h.SamplesPerFrame) = [];
    audiodata19(1:h.SamplesPerFrame) = [];
    audiodata20(1:h.SamplesPerFrame) = [];
    audiodata21(1:h.SamplesPerFrame) = [];
    audiodata22(1:h.SamplesPerFrame) = [];
    audiodata23(1:h.SamplesPerFrame) = [];
    audiodata24(1:h.SamplesPerFrame) = [];
    audiodata25(1:h.SamplesPerFrame) = [];
    audiodata26(1:h.SamplesPerFrame) = [];
    audiodata27(1:h.SamplesPerFrame) = [];
    audiodata28(1:h.SamplesPerFrame) = [];
    audiodata29(1:h.SamplesPerFrame) = [];
    audiodata30(1:h.SamplesPerFrame) = [];
    audiodata31(1:h.SamplesPerFrame) = [];
%    audiodata32(1:h.SamplesPerFrame) = [];
    d1 = audiodata1;
    d2 = audiodata2;
    d3 = audiodata3;
    d4 = audiodata4;
    d5 = audiodata5;
    d6 = audiodata6;
    d7 = audiodata7;
    d8 = audiodata8;
    d9 = audiodata9;
    d10 = audiodata10;
    d11 = audiodata11;
    d12 = audiodata12;
    d13 = audiodata13;
    d14 = audiodata14;
    d15 = audiodata15;
    d16 = audiodata16;
    d17 = audiodata17;
    d18 = audiodata18;
    d19 = audiodata19;
    d20 = audiodata20;
    d21 = audiodata21;
    d22 = audiodata22;
    d23 = audiodata23;
    d24 = audiodata24;
    d25 = audiodata25;
    d26 = audiodata26;
    d27 = audiodata27;
    d28 = audiodata28;
    d29 = audiodata29;
    d30 = audiodata30;
    d31 = audiodata31;
%    d32 = audiodata32;

    audiowrite(strcat(filenames{1},'-raw.wav'),d1,6000);
    audiowrite(strcat(filenames{2},'-raw.wav'),d2,6000);
    audiowrite(strcat(filenames{3},'-raw.wav'),d3,6000);
    audiowrite(strcat(filenames{4},'-raw.wav'),d4,6000);
    audiowrite(strcat(filenames{5},'-raw.wav'),d5,6000);
    audiowrite(strcat(filenames{6},'-raw.wav'),d6,6000);
    audiowrite(strcat(filenames{7},'-raw.wav'),d7,6000);
    audiowrite(strcat(filenames{8},'-raw.wav'),d8,6000);
    audiowrite(strcat(filenames{9},'-raw.wav'),d9,6000);
    audiowrite(strcat(filenames{10},'-raw.wav'),d10,6000);
    audiowrite(strcat(filenames{11},'-raw.wav'),d11,6000);
    audiowrite(strcat(filenames{12},'-raw.wav'),d12,6000);
    audiowrite(strcat(filenames{13},'-raw.wav'),d13,6000);
    audiowrite(strcat(filenames{14},'-raw.wav'),d14,6000);
    audiowrite(strcat(filenames{15},'-raw.wav'),d15,6000);
    audiowrite(strcat(filenames{16},'-raw.wav'),d16,6000);
    audiowrite(strcat(filenames{17},'-raw.wav'),d17,6000);
    audiowrite(strcat(filenames{18},'-raw.wav'),d18,6000);
    audiowrite(strcat(filenames{19},'-raw.wav'),d19,6000);
    audiowrite(strcat(filenames{20},'-raw.wav'),d20,6000);
    audiowrite(strcat(filenames{21},'-raw.wav'),d21,6000);
    audiowrite(strcat(filenames{22},'-raw.wav'),d22,6000);
    audiowrite(strcat(filenames{23},'-raw.wav'),d23,6000);
    audiowrite(strcat(filenames{24},'-raw.wav'),d24,6000);
    audiowrite(strcat(filenames{25},'-raw.wav'),d25,6000);
    audiowrite(strcat(filenames{26},'-raw.wav'),d26,6000);
    audiowrite(strcat(filenames{27},'-raw.wav'),d27,6000);
    audiowrite(strcat(filenames{28},'-raw.wav'),d28,6000);
    audiowrite(strcat(filenames{29},'-raw.wav'),d29,6000);
    audiowrite(strcat(filenames{30},'-raw.wav'),d30,6000);
    audiowrite(strcat(filenames{31},'-raw.wav'),d31,6000);
%    audiowrite(strcat(filenames{32},'-raw.wav'),d32,6000);

%{
%%%%%%%% NOTE: Filtering takes only about 1-2 seconds per channel.
    dfilt1 = tybutter(d1,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2 = tybutter(d2,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt3 = tybutter(d3,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt4 = tybutter(d4,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt5 = tybutter(d5,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt6 = tybutter(d6,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt7 = tybutter(d7,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt8 = tybutter(d8,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt9 = tybutter(d9,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt10 = tybutter(d10,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt11 = tybutter(d11,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt12 = tybutter(d12,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt13 = tybutter(d13,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt14 = tybutter(d14,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt15 = tybutter(d15,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt16 = tybutter(d16,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt17 = tybutter(d17,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt18 = tybutter(d18,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt19 = tybutter(d19,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt20 = tybutter(d20,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt21 = tybutter(d21,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt22 = tybutter(d22,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt23 = tybutter(d23,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt24 = tybutter(d24,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt25 = tybutter(d25,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt26 = tybutter(d26,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt27 = tybutter(d27,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt28 = tybutter(d28,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt29 = tybutter(d29,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt30 = tybutter(d30,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt31 = tybutter(d31,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
%    dfilt32 = tybutter(d32,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_1 = tybutter(d1,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_2 = tybutter(d2,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_3 = tybutter(d3,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_4 = tybutter(d4,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_5 = tybutter(d5,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_6 = tybutter(d6,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_7 = tybutter(d7,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_8 = tybutter(d8,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_9 = tybutter(d9,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_10 = tybutter(d10,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_11 = tybutter(d11,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_12 = tybutter(d12,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_13 = tybutter(d13,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_14 = tybutter(d14,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_15 = tybutter(d15,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_16 = tybutter(d16,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_17 = tybutter(d17,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_18 = tybutter(d18,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_19 = tybutter(d19,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_20 = tybutter(d20,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_21 = tybutter(d21,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_22 = tybutter(d22,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_23 = tybutter(d23,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_24 = tybutter(d24,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_25 = tybutter(d25,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_26 = tybutter(d26,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_27 = tybutter(d27,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_28 = tybutter(d28,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_29 = tybutter(d29,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_30 = tybutter(d30,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
    dfilt2_31 = tybutter(d31,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
%    dfilt32 = tybutter(d32,200,h.SampleRate,'high'); %attempt to read fs rather than supply it
%%%%%%%%%                dfilt200 = tybutter(d,200,h.SampleRate,'high'); %also do 200 Hz high-pass
        %save(strcat(fileNameAndPath{1},'.mat'),'d','dfilt','dfilt200');
%%%%%%%% NOTE: Writing files takes less than 1 second per channel.
    audiowrite(strcat(filenames{1},'-filt100.wav'),dfilt1,6000);
    audiowrite(strcat(filenames{2},'-filt100.wav'),dfilt2,6000);
    audiowrite(strcat(filenames{3},'-filt100.wav'),dfilt3,6000);
    audiowrite(strcat(filenames{4},'-filt100.wav'),dfilt4,6000);
    audiowrite(strcat(filenames{5},'-filt100.wav'),dfilt5,6000);
    audiowrite(strcat(filenames{6},'-filt100.wav'),dfilt6,6000);
    audiowrite(strcat(filenames{7},'-filt100.wav'),dfilt7,6000);
    audiowrite(strcat(filenames{8},'-filt100.wav'),dfilt8,6000);
    audiowrite(strcat(filenames{9},'-filt100.wav'),dfilt9,6000);
    audiowrite(strcat(filenames{10},'-filt100.wav'),dfilt10,6000);
    audiowrite(strcat(filenames{11},'-filt100.wav'),dfilt11,6000);
    audiowrite(strcat(filenames{12},'-filt100.wav'),dfilt12,6000);
    audiowrite(strcat(filenames{13},'-filt100.wav'),dfilt13,6000);
    audiowrite(strcat(filenames{14},'-filt100.wav'),dfilt14,6000);
    audiowrite(strcat(filenames{15},'-filt100.wav'),dfilt15,6000);
    audiowrite(strcat(filenames{16},'-filt100.wav'),dfilt16,6000);
    audiowrite(strcat(filenames{17},'-filt100.wav'),dfilt17,6000);
    audiowrite(strcat(filenames{18},'-filt100.wav'),dfilt18,6000);
    audiowrite(strcat(filenames{19},'-filt100.wav'),dfilt19,6000);
    audiowrite(strcat(filenames{20},'-filt100.wav'),dfilt20,6000);
    audiowrite(strcat(filenames{21},'-filt100.wav'),dfilt21,6000);
    audiowrite(strcat(filenames{22},'-filt100.wav'),dfilt22,6000);
    audiowrite(strcat(filenames{23},'-filt100.wav'),dfilt23,6000);
    audiowrite(strcat(filenames{24},'-filt100.wav'),dfilt24,6000);
    audiowrite(strcat(filenames{25},'-filt100.wav'),dfilt25,6000);
    audiowrite(strcat(filenames{26},'-filt100.wav'),dfilt26,6000);
    audiowrite(strcat(filenames{27},'-filt100.wav'),dfilt27,6000);
    audiowrite(strcat(filenames{28},'-filt100.wav'),dfilt28,6000);
    audiowrite(strcat(filenames{29},'-filt100.wav'),dfilt29,6000);
    audiowrite(strcat(filenames{30},'-filt100.wav'),dfilt30,6000);
    audiowrite(strcat(filenames{31},'-filt100.wav'),dfilt31,6000);
%    audiowrite(strcat(filenames{32},'-filt100.wav'),dfilt32,6000);
    audiowrite(strcat(filenames{1},'-filt200.wav'),dfilt2_1,6000);
    audiowrite(strcat(filenames{2},'-filt200.wav'),dfilt2_2,6000);
    audiowrite(strcat(filenames{3},'-filt200.wav'),dfilt2_3,6000);
    audiowrite(strcat(filenames{4},'-filt200.wav'),dfilt2_4,6000);
    audiowrite(strcat(filenames{5},'-filt200.wav'),dfilt2_5,6000);
    audiowrite(strcat(filenames{6},'-filt200.wav'),dfilt2_6,6000);
    audiowrite(strcat(filenames{7},'-filt200.wav'),dfilt2_7,6000);
    audiowrite(strcat(filenames{8},'-filt200.wav'),dfilt2_8,6000);
    audiowrite(strcat(filenames{9},'-filt200.wav'),dfilt2_9,6000);
    audiowrite(strcat(filenames{10},'-filt200.wav'),dfilt2_10,6000);
    audiowrite(strcat(filenames{11},'-filt200.wav'),dfilt2_11,6000);
    audiowrite(strcat(filenames{12},'-filt200.wav'),dfilt2_12,6000);
    audiowrite(strcat(filenames{13},'-filt200.wav'),dfilt2_13,6000);
    audiowrite(strcat(filenames{14},'-filt200.wav'),dfilt2_14,6000);
    audiowrite(strcat(filenames{15},'-filt200.wav'),dfilt2_15,6000);
    audiowrite(strcat(filenames{16},'-filt200.wav'),dfilt2_16,6000);
    audiowrite(strcat(filenames{17},'-filt200.wav'),dfilt2_17,6000);
    audiowrite(strcat(filenames{18},'-filt200.wav'),dfilt2_18,6000);
    audiowrite(strcat(filenames{19},'-filt200.wav'),dfilt2_19,6000);
    audiowrite(strcat(filenames{20},'-filt200.wav'),dfilt2_20,6000);
    audiowrite(strcat(filenames{21},'-filt200.wav'),dfilt2_21,6000);
    audiowrite(strcat(filenames{22},'-filt200.wav'),dfilt2_22,6000);
    audiowrite(strcat(filenames{23},'-filt200.wav'),dfilt2_23,6000);
    audiowrite(strcat(filenames{24},'-filt200.wav'),dfilt2_24,6000);
    audiowrite(strcat(filenames{25},'-filt200.wav'),dfilt2_25,6000);
    audiowrite(strcat(filenames{26},'-filt200.wav'),dfilt2_26,6000);
    audiowrite(strcat(filenames{27},'-filt200.wav'),dfilt2_27,6000);
    audiowrite(strcat(filenames{28},'-filt200.wav'),dfilt2_28,6000);
    audiowrite(strcat(filenames{29},'-filt200.wav'),dfilt2_29,6000);
    audiowrite(strcat(filenames{30},'-filt200.wav'),dfilt2_30,6000);
    audiowrite(strcat(filenames{31},'-filt200.wav'),dfilt2_31,6000);
%    audiowrite(strcat(filenames{32},'-filt200.wav'),dfilt2_32,6000);
%}    
    
    
    
    
    % Track time to complete processing.
    t1 = datetime('now');
    tdif = t1 - t0;
    disp(tdif);
    
    
    fclose(errorout);
    fclose(mainout);
    fclose(wavFile);
end

%only care about male species when finding the folder
%function findFolder(folderMap, maleSpecies)
function fullDir = findFolder(folderMap, maleSpecies, strain) %added strain and specified output as fullDir 6/4/15
    folderDir = 'D:\SoundData\NewPerSpeciesRecordingsMono\test_matt\'; %moved from top 6/4/15
%    folderDir = 'D:\SoundData\NewPerSpeciesRecordingsMono\'; %moved from top 6/4/15
    folder = maleSpecies; %set a folder name in case no values match 6/4/15
    allKeys = keys(folderMap);
    %also make a dictionary for the 'palli' names:
    strainMap = containers.Map();
    strainMap('pallidosa') = {'01','20001','"01"','"20001"','2001','".00"'};
    strainMap('pallidifrons') = {'PN175','pn175'};
    for key = allKeys
        %currentValues = values(folderMap, {key});
        currentValues = values(folderMap, key); %replaced previous line 6/4/15

        %if maleSpecies == 'palli'
        if strcmp(maleSpecies,'palli') == 1 %replaced previous line 6/4/15
            %if strain == '01' || strain == 20001 %figure out what column the strain is
            %if strcmp(strain,'"01"') == 1 || strcmp(strain, '20001') == 1 %replaced previous line 6/4/15
            if sum(ismember(strainMap('pallidosa'),strain)) > 0
                folder = {'pallidosa'};
            elseif sum(ismember(strainMap('pallidifrons'),strain)) > 0
                %strain == 'pn175'  %^^find out strain (see above)
                %OR switch else and if so less work
                folder = {'pallidifrons'};
            else
                folder = 'unknown'; %this will trigger an error
            end    
        else
            for value = currentValues
                innerval = value{1}; %added 6/4/15
                length(innerval);
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
    fullDir = strcat(folderDir, folder);
end


function dateString = convertDate(dateRaw) %modified to specify output as dateString 6/4/15
    %modified to handle non-date rows 6/4/15
    tempDate = strsplit(dateRaw, '/');
    %need to add together the 3 different pieces
    if length(tempDate{1}) == 1
        tempDate{1} = strcat('0', tempDate{1});
    end
    if length(tempDate{2}) == 1
        tempDate{2} = strcat('0', tempDate{2});
    end
    if length(tempDate) == 3
        dateString = strcat(tempDate{3}, tempDate{1}, tempDate{2});
    else
        dateString = 'NA'; %for blank/'Date' rows 6/4/15
    end
end
