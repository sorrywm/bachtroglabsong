function RunClusteringOneChannelFilt5pmLoadOpts(wav_file, prevtempfile, whichsignal, ipiptl, segopts)
    %To do: generate both IPI and PTL/PPB plots/files by default
    %To do: Allow PTL/PPB analyses with 5-pulse minimum
    %To do: Separate pulse trains with </> an IPI threshold (50?) for PTL/PPB
    %analysis
    %To do: Enable specification of minimum pulse number
    %To do: Load previously assigned data if available
    %To do: Save output files in a different folder.
    %Alternative: Move files after creating them (in bash wrapper).
    %To do: Don't change directories. Just add paths (check if multiple
    %paths have same script names).
    %Modify the following to the location of your versions of these programs.
    %Alternatively, create a structure with these filenames saved,
    %and load it as part of the code.
    relvars = {'fs','diffThreshold','template_pca_dimension'};
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:});
    else
        analyzerdir = '../FlySongClusterSegment/';
        plotanalyzerdir = '../fly_song_analyzer_032412/';
        butterdir = pwd;
        fs = 6000; %read from file?
        diffThreshold = 20;
        template_pca_dimension = 10;
        wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
        filtcut=200;
        isshort='n';
    end

    addpath(segmenterdir,plotanalyzerdir,butterdir);
    currentFolder = pwd;
    %Added in some code to allow calculation of pulse train length rather than
    %IPI
    %Estimate runtime:
    tic;
    if nargin < 4 || isempty(ipiptl)
        ipiptl = 'IPI';
        if nargin < 3 || isempty(whichsignal)
            whichsignal = [1 2 3 4 5 6 7 8 9 10 11 12];
                if nargin < 2 || isempty(prevtempfile)
                    prevtempfile = 'J:/SoundData/PerSpeciesRecordingsMono/ssulf/Channel1_122214_ssulf.wav_dataSSulfurigasterTemplatesFromChannel1_122214.mat';
                    if nargin < 1 || isempty(wav_file)
                        wav_file = 'J:/SoundData/PerSpeciesRecordingsMono/ssulf/Channel1_122214_ssulf.wav'; %location of wavfile
                    end
            end
        end
    end

    song_range = [];
    outname = strcat(wav_file,'_data');
    [~,wavbase,ext] = fileparts(wav_file);
    splittempname = strsplit(prevtempfile,'/');
    newtempoutname = splittempname{length(splittempname)};
    maxIPI = 0.2; %maximum IPI before a new bout is formed (in s)

    %First, check whether data already exists:
    %If d exists but dfilt does not, just filter d.
    %If data does not exist, grab the wav file.
    %If the wav file does not exist, error out.
    if exist(strcat(outname,'.mat'),'file') == 2
        d = load(strcat(outname,'.mat'));
        if isfield(d,'dfilt') == 0
            fprintf('Grabbing song from wav file to filter and resave: %s.\n', wav_file);
            if exist(wav_file) == 2
                if ~isempty(song_range)
                   song = audioread(wav_file,song_range);
                else
                    song = audioread(wav_file);
                end
                %Save this file
                d=song;
                %cd(butterdir);
                dfilt = tybutter(d,filtcut,fs,'high');
                save(strcat(outname,'.mat'),'d','dfilt');
            else
                error('Wav file does not exist: %s.\n', wav_file);
            end
        else
            dfilt=d.dfilt;
        end
    else   
        %Generate a data file from the .wav file
        fprintf('Grabbing song from wav file %s.\n', wav_file);
        if ~isempty(song_range)
            song = audioread(wav_file,song_range);
        else
            song = audioread(wav_file);
        end
        %Save this file
        d=song;
        %cd(butterdir);
        dfilt = tybutter(d,filtcut,fs,'high');
        save(strcat(outname,'.mat'),'d','dfilt');
    end

    %Load in previously computed templates.
    fprintf('Loading previous templates: %s.\n', prevtempfile);
    load(prevtempfile);
    if length(whichsignal) > length(newtemplates)
        fprintf('Keeping all signals: %s.\n', num2str(length(newtemplates)));
        whichsignal = whichsignal{1:length(newtemplates)};
    end

    %Create 'options' structure.
    %wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
    shortoptions = struct('fs',6000,'diffThreshold',3,'template_pca_dimension',5);
    wmoptions10 = struct('fs',6000,'diffThreshold',10,'template_pca_dimension',10);
    wmoptions30 = struct('fs',6000,'diffThreshold',30,'template_pca_dimension',10);
    %Reduced PCA dimension (default 50) because of following error:
    %Index exceeds matrix dimensions.
    %Error in createTemplates (line 70)
    %    scores = scores(:,1:options.template_pca_dimension);

    %Set directory to location of fly_song_analyzer.
    cd(plotanalyzerdir);
    %Assign data to templates.
    %Time this.
    if isshort == 'y'
        %tic;
        fprintf('Using short IPI options.\n');
        fprintf('Assigning data to templates from %s.\n', prevtempfile);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,shortoptions);
        %toc;
    else
        %tic;
        fprintf('Assigning data to templates from %s.\n', prevtempfile);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
        %toc;
    end
    %Save these variables... including which templates you called signals.
    dataoutname = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'assigned.mat');
    save(dataoutname,'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds','whichsignal');

    %Plot all templates and just signal templates.
    if isshort == 'y'
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outname,newtempoutname,'ShortAllColored.fig'));
        makePeakPlot(dfilt, peakIdxGroup, whichsignal);
        savefig(strcat(outname,newtempoutname,'ShortSignalColored.fig'));
    else
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outname,newtempoutname,'AllColored.fig'));
        makePeakPlot(dfilt, peakIdxGroup, whichsignal);
        savefig(strcat(outname,newtempoutname,'SignalColored.fig'));
    end

    %Compute and plot IPI.
    %Use all peaks, rather than template 1?
    %Goal: use just peaks from signal templates
    %If just using one template:
    %w = diff(peakIdxGroup{1})./options.fs;
    %1) How can we select just signal templates?
    %2) How can we use peakIdxGroup for multiple templates?
    %signaltemplates = [1 2 3 4 5 6 7];
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);

    if strcmp(ipiptl, 'IPI') == 1
        %w = diff(allPeakIdx)./wmoptions.fs;
        wall = diff(signalPeakIdx)./wmoptions.fs;
        w = wall(wall <= maxIPI);
        display(length(w))
        %wcount = length(w);
        wout = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
        %Save IPI distribution.
        %Also save to text file for R manipulation.
        %save(strcat(wout,'.mat'),'w','wall');
        save(strcat(wout,'.txt'),'w','-ascii'); 
        %%% New code here:
        %Filter to include only pulses in trains of at least 5 pulses:
        isConnected = wall <= maxIPI;
        CC = bwconncomp(isConnected);
        tokeep = [];
        for i=1:CC.NumObjects
            numPulses = length(CC.PixelIdxList{i});
            if numPulses > 4
                tokeep = [tokeep signalPeakIdx(CC.PixelIdxList{i}) signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            end
        end
        tokeep = sort(tokeep);
        w5all = diff(tokeep)./wmoptions.fs;
        w5 = w5all(w5all <= maxIPI);
        display(length(w5))
        save(strcat(wout,'.mat'),'w','wall','w5','w5all');
        save(strcat(wout,'min5pulse.txt'),'w5','-ascii');
        %%% New code ends.
        %Model IPI distribution as a mixture of Gaussians.
        %Now doing mixture model in R, so don't need to spend time on it here.
        %ipigm2 = fitgmdist(w.',2)
        %ipigm3 = fitgmdist(w.',3)
        %ipigm4 = fitgmdist(w.',4)

        %Find some way to save means and proportions to text?
        %gmout = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'GMModel');
        %save(strcat(gmout,'.mat'),'ipigm2','ipigm3','ipigm4');
        %save(strcat(gmout,'.txt'),'wav_file','wcount','ipigm2','-ascii');

        [Y,X] = hist(w,100); %switch to 'histogram' in more recent releases of MATLAB
        Y = Y  ./ (sum(Y)*(X(2)-X(1)));
        plot(X*1000,Y)
        title(strcat('IPI histogram for ',wavbase))
        xlabel('Inter-pulse interval (IPI), in ms')
        ylabel ('Count')
        if isshort == 'y'
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesIPIHistShort.fig'));
        else
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesIPIHist.fig'));
        end
        %also plot just 5-pulse IPIs
        [Y,X] = hist(w5,100); %switch to 'histogram' in more recent releases of MATLAB
        Y = Y  ./ (sum(Y)*(X(2)-X(1)));
        plot(X*1000,Y)
        title(strcat('5-pulse minimum IPI histogram for ',wavbase))
        xlabel('Inter-pulse interval (IPI), in ms')
        ylabel ('Count')
        if isshort == 'y'
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesIPIHistShort5pm.fig'));
        else
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesIPIHist5pm.fig'));
        end
        %sortY = fliplr(sort(Y)); %order the counts from most to least
        %for i=1:10
        %    X(find(Y==sortY(i)))*1000 %print the top 10 X values.... should contain the mode
        %end
    elseif strcmp(ipiptl,'PTL') == 1
        %From Gordon:
        %This is a little trickier, as it requires something of a heuristic.  
        %For example, you will need to decide what defines the end of a train (i.e. no pulse in ??? ms after the previous pulse).  
        %Given that definition, though, you could do something like this:
        %Let ts be a sorted array containing the “spike times” of the detected pulses 
        %and tMax be the maximum time separation at which two consecutive pulses are in the same train.
        %Then, you could run the following lines of code (or something similar):
        ts = signalPeakIdx./wmoptions.fs;
        tMax = maxIPI;
        isConnected = diff(ts) < tMax;
        CC = bwconncomp(isConnected);
        fprintf('Number of objects (pulse trains): %s\n', num2str(CC.NumObjects));
        numPulses = zeros(CC.NumObjects,1);
        trainLengths = zeros(CC.NumObjects,1);
        for i=1:CC.NumObjects
            numPulses(i) = length(CC.PixelIdxList{i});
            trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        end
        ptldataoutname = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'PTLdata.mat');
        save(ptldataoutname,'CC','numPulses','trainLengths');
        intnumPulses = numPulses(numPulses < 100);
        [Y,X] = hist(intnumPulses,50); %switch to 'histogram' in more recent releases of MATLAB
        Y = Y  ./ (sum(Y)*(X(2)-X(1)));
        plot(X,Y)
        %xlim([0 100])
        title(strcat('PPB histogram for ',wavbase))
        xlabel('Pulses per burst (PPB)')
        ylabel ('Count')
        if isshort == 'y'
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesPPBHistShort.fig'));
        else
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesPPBHist.fig'));
        end
        inttrainLengths = trainLengths(trainLengths < 1.5);
        [Y,X] = hist(inttrainLengths,50); %switch to 'histogram' in more recent releases of MATLAB
        Y = Y  ./ (sum(Y)*(X(2)-X(1)));
        plot(X*1000,Y)
        %xlim([0 1500])
        title(strcat('PTL histogram for ',wavbase))
        xlabel('Pulse Train Length (PTL), in ms')
        ylabel ('Count')
        if isshort == 'y'
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesPTLHistShort.fig'));
        else
            savefig(strcat(outname,newtempoutname,'FiltSignalTemplatesPTLHist.fig'));
        end
    else
        fprintf('ipiptl variable must be either IPI or PTL: %s.\n', ipiptl);
    end
    %whos
    %cd(segmenterdir);
    cd(currentFolder);
    toc;

