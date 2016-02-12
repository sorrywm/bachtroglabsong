function RunClusteringVirilis(wav_file, prevtempfile, whichsignal, ipiptl, segopts)
    %To do: Load previously assigned data if available
    %To do: Save output files in a different folder.
    %To do: Make saving male and female separately optional.
    %Alternative: Move files after creating them (in bash wrapper).
    %Now uses addpath rather than changing directories. 
    %If any issues, check if multiple paths have same script names).
    %Added option: ipiptl can be 'IPI','PTL', or 'both'
    %PTL/PPB analysis now ONLY run with 5-pulse minimum (not all trains)
    %Parameters now saved separately for male and female (using 'femalecut'
    %for IPI threshold)
    relvars = {'fs','diffThreshold','template_pca_dimension'};
    femalecut = 25; %test this... potentially add to opts
    pulsetrainmax = 100;
    trainlengthmax = 1.5; %in seconds
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:});
    else
        %Modify the following to the location of your versions of these programs.
        %Alternatively, save these locations and load as segopts.
        analyzerdir = '../FlySongClusterSegment/';
        plotanalyzerdir = '../fly_song_analyzer_032412/';
        segmenterdir = '../FlySongSegmenter/';
        chronuxdir = '../FlySongSegmenter/chronux/';
        butterdir = pwd;
        fs = 6000; %read from file?
        diffThreshold = 20;
        template_pca_dimension = 10;
        wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
        filtcut=200;
        isshort='n';
    end

    addpath(segmenterdir,plotanalyzerdir,butterdir,chronuxdir);
    currentFolder = pwd;

    %Estimate runtime:
    tic;
    if nargin < 4 || isempty(ipiptl)
        ipiptl = 'IPI';
        if nargin < 3 || isempty(whichsignal)
            whichsignal = [1 2 3 4 5 6 7 8 9 10 11 12];
                if nargin < 2 || isempty(prevtempfile)
                    prevtempfile = ...
                        'J:/SoundData/PerSpeciesRecordingsMono/ssulf/Channel1_122214_ssulf.wav_dataSSulfurigasterTemplatesFromChannel1_122214.mat';
                    if nargin < 1 || isempty(wav_file)
                        wav_file = ...
                            'J:/SoundData/PerSpeciesRecordingsMono/ssulf/Channel1_122214_ssulf.wav'; %location of wavfile
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

    %Set directory to location of fly_song_analyzer.
    %cd(plotanalyzerdir);
    %Assign data to templates.
    %Time this?
    %tic;
    fprintf('Assigning data to templates from %s.\n', prevtempfile);
    try
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,...
        coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
    catch MEadtt
        display(path)
        rethrow(MEadtt)
    end
    %toc;
    %Save these variables... including which templates you called signals.
    dataoutname = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal), ...
        'maxIPI',num2str(maxIPI),'assigned.mat');
    save(dataoutname,'groupings','peakIdxGroup','likes','allPeakIdx', ...
        'allNormalizedPeaks','coeffs','projStds','whichsignal');

    %Plot all templates and just signal templates.
    makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
    savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'AllColored.fig'));
    makePeakPlot(dfilt, peakIdxGroup, whichsignal);
    savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'SignalColored.fig'));

    %Compute and plot IPI.

    %Get peakIdx for all signal peaks.
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);

    %Get IPI.
    wall = diff(signalPeakIdx)./wmoptions.fs;
    w = wall(wall <= maxIPI);
    fprintf('Number of IPI measurements less than %s s %s\n', maxIPI, length(w));
    ts = signalPeakIdx./wmoptions.fs;
    
    %%% New code here:
    %Filter to include only pulses in trains of at least 5 pulses:
    %New: also split into male and female based on mean IPI.
    isConnected = wall <= maxIPI;
    CC = bwconncomp(isConnected);
    tokeep = [];
    tokeepmale = [];
    tokeepfemale = [];
    %Track pulses per burst and pulse train length.
    numPulses = zeros(CC.NumObjects,1);
    numpulsesfemale = [];
    numpulsesmale = [];
    trainLengths = zeros(CC.NumObjects,1);
    trainlengthsfemale = [];
    trainlengthsmale = [];

    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        if numPulses(i) > 4
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            medianipi = median(diff(pulsestoadd)./wmoptions.fs);
            tokeep = [tokeep pulsestoadd];
            if medianipi > femalecut
                tokeepfemale = [tokeepfemale pulsestoadd];
                numpulsesfemale = [numpulsesfemale numPulses(i)];
                trainlengthsfemale = [trainlengthsfemale trainLengths(i)];
            else
                tokeepmale = [tokeepmale pulsestoadd];
                numpulsesmale = [numpulsesmale numPulses(i)];
                trainlengthsmale = [trainlengthsmale trainLengths(i)];
            end
        end
    end
    if strcmp(ipiptl, 'IPI') == 1 || strcmp(ipiptl, 'both') == 1
        wout = strcat(outname,newtempoutname,'dt',num2str(diffThreshold), ...
            'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
        %Save IPI distribution.
        %Also save to text file for R manipulation.
        %save(strcat(wout,'.mat'),'w','wall');
        save(strcat(wout,'.txt'),'w','-ascii'); 

        %New function for sorting and saving pulse trains
        [tokeep, w5] = sortAndSavePulseTrains(tokeep, wmoptions.fs, ...
            maxIPI, 'all', wout);
        [tokeepmale, w5male] = sortAndSavePulseTrains(tokeepmale, wmoptions.fs, ...
            maxIPI, 'male', wout);
        [tokeepfemale, w5female] = sortAndSavePulseTrains(tokeepfemale, wmoptions.fs, ...
            maxIPI, 'female', wout);
        
        %New code for plotting histograms
        plotParameterHist(w, 100, 'IPI', wavbase, 'Inter-pulse interval (IPI), in ms', ...
        strcat(outname,newtempoutname,'FiltdT',num2str(diffThreshold), ...
        'SignalTemplatesIPIHist.fig'));
        
        %also plot just 5-pulse IPIs
        plotParameterHist(w5, 100, '5-pulse minimum IPI', wavbase, ...
            'Inter-pulse interval (IPI), in ms', strcat(outname, ...
            newtempoutname,'FiltdT',num2str(diffThreshold), ...
            'SignalTemplatesIPIHist5pm.fig'));
        %sortY = fliplr(sort(Y)); %order the counts from most to least
        %for i=1:10
        %    X(find(Y==sortY(i)))*1000 %print the top 10 X values.... should contain the mode
        %end
        
    elseif strcmp(ipiptl,'PTL') == 1 || strcmp(ipiptl,'both') == 1
        %ipiptl now only influences what to save.
        %from IPI: wout = strcat(outname,newtempoutname,'dt',num2str(diffThreshold), ...
          %  'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
        ptlout = strcat(outname,newtempoutname,'dt',num2str(diffThreshold), ...
            'signal', sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'PTL');
        save(strcat(ptlout,'data.mat'),'CC','numPulses','trainLengths', ...
            'numpulsesfemale', 'numpulsesmale', 'trainlengthsfemale', 'trainlengthsmale');

        intnumPulses = numPulses(numPulses < numpulsemax);
        plotParameterHist(intnumPulses/1000, 50, 'PPB', wavbase, 'Pulses per burst (PPB)', ...
            strcat(outname,newtempoutname,'FiltdT',num2str(diffThreshold), ...
            'SignalTemplatesPPBHist5pm.fig'));
        
        inttrainLengths = trainLengths(trainLengths < pulsetrainmax);
        plotParameterHist(inttrainlengths, 50, 'PTL', wavbase, ...
            'Pulse Train Length (PTL), in ms', strcat(outname,newtempoutname,...
            'FiltdT',num2str(diffThreshold),'SignalTemplatesPTLHist5pm.fig'));
    else
        fprintf('ipiptl variable must be IPI, PTL, or both: %s.\n', ipiptl);
    end
    %whos
    %cd(segmenterdir);
    %cd(currentFolder);
    toc;
end

function [pulses, ipis] = sortAndSavePulseTrains(unsortedpulses, sampfreq, ...
        ipicut, pulselabel, pulseoutfile);
    pulses = sort(unsortedpulses);
    w5all = diff(pulses)./sampfreq;
    w5 = w5all(w5all <= ipicut);
    fprintf('Number of  %s pulse trains with at least 5 pulses: %s\n', ...
        pulselabel, num2str(length(w5)))
    save(strcat(pulseoutfile,pulselabel,'.mat'),'w','wall','w5','w5all');
    save(strcat(pulseoutfile,puplselabel,'min5pulse.txt'),'w5','-ascii');
    ipis = w5;
end

function plotParameterHist(values, hbreaks, parname, wavname, xaxlabel, plotoutname)
    [Y,X] = hist(values, hbreaks); %switch to 'histogram' in more recent releases of MATLAB
    Y = Y  ./ (sum(Y)*(X(2)-X(1)));
    plot(X*1000,Y)
    title(strcat(parname,' histogram for ',wavname))
    xlabel(xaxlabel)
    ylabel ('Count')
    savefig(plotoutname);
end

%Currently doing mixture modeling in R, but the following
%could serve as a base for doing this analysis in MATLAB.
%Model IPI distribution as a mixture of Gaussians.
%Now doing mixture model in R, so don't need to spend time on it here.
%ipigm2 = fitgmdist(w.',2)
%ipigm3 = fitgmdist(w.',3)
%ipigm4 = fitgmdist(w.',4)

%Find some way to save means and proportions to text?
%gmout = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'GMModel');
%save(strcat(gmout,'.mat'),'ipigm2','ipigm3','ipigm4');
%save(strcat(gmout,'.txt'),'wav_file','wcount','ipigm2','-ascii');
