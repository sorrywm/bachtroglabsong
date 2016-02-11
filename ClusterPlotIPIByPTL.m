function ClusterPlotIPIByPTL(wav_file, prevtempfile, whichsignal, ipiptl, segopts, doplots)
    %Plot median IPI by PTL/PPB for all pulse trains.
    %To do: Save pulse train parameters together so cutoff can be adjusted
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
    %Template filename taken out of final filename (too long)
    if nargin < 6
        doplots = 'TRUE';
    end
    clearvars -except wav_file prevtempfile whichsignal ipiptl segopts doplots;
    relvars = {'fs','diffThreshold','template_pca_dimension'};
    femalecut = 0.025; %test this... potentially add to opts
    numpulsemax = 100;
    pulsetrainmax = 1.5; %in seconds
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        %song_range (optional: for subsetting a song)
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
        domalefemale='FALSE';
    end

    addpath(segmenterdir,plotanalyzerdir,butterdir,chronuxdir);
    currentFolder = pwd;

    %Estimate runtime:
    tic;

    if exist('song_range','var')==0
        song_range = [];
        outname = strcat(wav_file,'_data');
    else
        outname = strcat(wav_file,num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
    end
    [~,wavbase,ext] = fileparts(wav_file);
    splittempname = strsplit(prevtempfile,'/');
    newtempoutname = splittempname{length(splittempname)};
    %Modified maxIPI for sulfurigaster... switch to 0.2 for pulaua
    maxIPI = 0.1; %maximum IPI before a new bout is formed (in s)

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
        try
            whichsignal = whichsignal{1:length(newtemplates)};
        catch MEtemp
            disp(whichsignal)
            disp(length(newtemplates))
            rethrow(MEtemp)
        end
    end

    %Assign data to templates.
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
    %dataoutname = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal), ...
    dataoutname = strcat(outname,'signal',sprintf('%d',whichsignal), ...
        'maxIPI',num2str(maxIPI),'assigned.mat');
    save(dataoutname,'groupings','peakIdxGroup','likes','allPeakIdx', ...
        'allNormalizedPeaks','coeffs','projStds','whichsignal');

    %Plot all templates and just signal templates.
    if strcmp(doplots,'TRUE')
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        %savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'AllColored.fig'));
        savefig(strcat(outname,'dT',num2str(diffThreshold),'AllColored.fig')),
        makePeakPlot(dfilt, peakIdxGroup, whichsignal);
        %savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'SignalColored.fig'));
        savefig(strcat(outname,'dT',num2str(diffThreshold),'SignalColored.fig'));
    end
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
    numPulses5pm = [];
    numpulsesfemale = [];
    numpulsesmale = [];
    %trainLengths = zeros(CC.NumObjects,1);
    trainLengths = [];
    trainlengthsfemale = [];
    trainlengthsmale = [];
    medipi = []

    if exist('minpulse','var')==0
        minpulse = 5;
    end
    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        %trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        if numPulses(i) > (minpulse - 1)
            trainLengths = [trainLengths ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1))];
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            medipi = [medipi median(diff(pulsestoadd)./wmoptions.fs)];
            tokeep = [tokeep pulsestoadd];
            numPulses5pm = [numPulses5pm numPulses(i)];
            if strcmp(domalefemale,'TRUE')
                medianipi = median(diff(pulsestoadd)./wmoptions.fs);
                if medianipi > femalecut
                    tokeepfemale = [tokeepfemale pulsestoadd];
                    numpulsesfemale = [numpulsesfemale numPulses(i)];
                    trainlengthsfemale = [trainlengthsfemale trainLengths(end)];
                else
                    tokeepmale = [tokeepmale pulsestoadd];
                    numpulsesmale = [numpulsesmale numPulses(i)];
                    trainlengthsmale = [trainlengthsmale trainLengths(end)];
                end
            end
        end
    end
    ipdone = 0;
    if strcmp(ipiptl, 'IPI') == 1 || strcmp(ipiptl, 'both') == 1
        %wout = strcat(outname,newtempoutname,'dt',num2str(diffThreshold), ...
        wout = strcat(outname,'dT',num2str(diffThreshold), ...
            'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
        %Save IPI distribution.
        %Also save to text file for R manipulation.
        %save(strcat(wout,'.mat'),'w','wall');
        %save(strcat(wout,'.txt'),'w','-ascii'); 
        dlmwrite(strcat(wout,'.txt'),w,'delimiter','\n');
        %New function for sorting and saving pulse trains
        %No longer saves 'w' in output file, just 'w5' (excluding pulse trains shorter than 5)
        [tokeep, w5] = sortAndSavePulseTrains(tokeep, wmoptions.fs, ...
            maxIPI, 'all', wout);
        if strcmp(domalefemale,'TRUE')
            [tokeepmale, w5male] = sortAndSavePulseTrains(tokeepmale, wmoptions.fs, ...
                maxIPI, 'male', wout);
            [tokeepfemale, w5female] = sortAndSavePulseTrains(tokeepfemale, wmoptions.fs, ...
                maxIPI, 'female', wout);
        end
        if strcmp(doplots, 'TRUE')
            %New code for plotting histograms
            plotParameterHist(w, 100, 'IPI', wavbase, 'Inter-pulse interval (IPI), in ms', ...
                strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'Signal',sprintf('%d',whichsignal),'TemplatesIPIHist.jpg'));
        
            %also plot just 5-pulse IPIs
            plotParameterHist(w5, 100, '5-pulse minimum IPI', wavbase, ...
                'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                'FiltdT',num2str(diffThreshold), ...
                'Signal',sprintf('%d',whichsignal),'TemplatesIPIHist5pm.jpg'));

            %new: plot median IPI by PPB and PTL.
            splt=scatter(medipi*1000,numPulses5pm,25,medipi,'filled')
            saveas(splt,strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesIPIbyPPB.jpg'));
            splt2=scatter(medipi*1000,trainLengths,25,medipi,'filled');
            saveas(splt2,strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'Signal',sprintf('%d',whichsignal),'TemplatesIPIbyPTL.jpg'));

            if strcmp(domalefemale,'TRUE')
                %Plot female and male IPIs separately.
                plotParameterHist(w5female, 100, '5-pulse minimum IPI female', wavbase, ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'Signal',sprintf('%d',whichsignal),'TemplatesFemaleIPIHist5pm.jpg'));
                plotParameterHist(w5male, 100, '5-pulse minimum IPI male', wavbase, ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'Signal',sprintf('%d',whichsignal),'TemplatesMaleIPIHist5pm.jpg'));
            end
        end
        ipdone = 1;
    end    
    if strcmp(ipiptl,'PTL') == 1 || strcmp(ipiptl,'both') == 1
        %ipiptl now only influences what to save.
        %from IPI: wout = strcat(outname,newtempoutname,'dt',num2str(diffThreshold), ...
          %  'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
        %ptlout = strcat(outname,newtempoutname,'dT',num2str(diffThreshold), ...
        ptlout = strcat(outname,'dT',num2str(diffThreshold), ...
            'signal', sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI));
        %save(strcat(ptlout,'allPTL.txt'),'trainLengths','-ascii');
        dlmwrite(strcat(ptlout,'allPTL.txt'),trainLengths,'delimiter','\n');
        %save(strcat(ptlout,'allPPB.txt'),'numPulses','-ascii');
        dlmwrite(strcat(ptlout,'allPPB.txt'),numPulses,'delimiter','\n');
        dlmwrite(strcat(ptlout,'allPPB5pm.txt'),numPulses5pm,'delimiter','\n');
        if strcmp(domalefemale,'TRUE')
            save(strcat(ptlout,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths', ...
                'numpulsesfemale', 'numpulsesmale', 'trainlengthsfemale', 'trainlengthsmale');
            %Also save all 5-pulse min values to text files
            dlmwrite(strcat(ptlout,'femalePTL.txt'),trainlengthsfemale,'delimiter','\n');
            dlmwrite(strcat(ptlout,'malePTL.txt'),trainlengthsmale,'delimiter','\n');
            dlmwrite(strcat(ptlout,'femalePPB.txt'),numpulsesfemale,'delimiter','\n');
            dlmwrite(strcat(ptlout,'malePPB.txt'),numpulsesmale,'delimiter','\n');
        else
            save(strcat(ptlout,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths');
        end
        if strcmp(doplots,'TRUE')
            %intnumPulses = numPulses(numPulses < numpulsemax);
            intnumPulses = numPulses5pm(numPulses5pm < numpulsemax);
            plotParameterHist(intnumPulses/1000, 50, 'PPB', wavbase, 'Pulses per burst (PPB)', ...
                strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesPPBHist5pm.jpg'));
        
            inttrainLengths = trainLengths(trainLengths < pulsetrainmax);
            plotParameterHist(inttrainLengths, 50, 'PTL', wavbase, ...
                'Pulse Train Length (PTL), in ms', strcat(outname, ...
                'FiltdT',num2str(diffThreshold),'SignalTemplatesPTLHist5pm.jpg'));

            if strcmp(domalefemale,'TRUE')
                %Plot male and female separately.
                intnumpulsesfemale = numpulsesfemale(numpulsesfemale < numpulsemax);
                plotParameterHist(intnumpulsesfemale/1000, 50, 'PPB', wavbase, 'Pulses per burst (PPB) female', ...
                    strcat(outname,'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesFemalePPBHist5pm.jpg'));

                inttrainlengthsfemale = trainlengthsfemale(trainlengthsfemale < pulsetrainmax);
                plotParameterHist(inttrainlengthsfemale, 50, 'PTL', wavbase, ...
                    'Pulse Train Length (PTL) female, in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold),'SignalTemplatesFemalePTLHist5pm.jpg'));
        
                intnumpulsesmale = numpulsesmale(numpulsesmale < numpulsemax);
                plotParameterHist(intnumpulsesmale/1000, 50, 'PPB', wavbase, 'Pulses per burst (PPB) male', ...
                    strcat(outname,'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesMalePPBHist5pm.jpg'));

                inttrainlengthsmale = trainlengthsmale(trainlengthsmale < pulsetrainmax);
                plotParameterHist(inttrainlengthsmale, 50, 'PTL', wavbase, ...
                    'Pulse Train Length (PTL) male, in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold),'SignalTemplatesMalePTLHist5pm.jpg'));
            end
        end
        ipdone = 1;
    end
    if ipdone ~= 1
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
    save(strcat(pulseoutfile,pulselabel,'.mat'),'w5','w5all');
    dlmwrite(strcat(pulseoutfile,pulselabel,'min5pulse.txt'),w5,'delimiter','\n');
    ipis = w5;
end

function plotParameterHist(values, hbreaks, parname, wavname, xaxlabel, plotoutname)
    %disp(plotoutname)
    if hbreaks > length(values)/10
        hbreaks = max(round(length(values)/10),10);
    end
    [Y,X] = hist(values, hbreaks); %switch to 'histogram' in more recent releases of MATLAB
    Y = Y  ./ (sum(Y)*(X(2)-X(1)));
    plot(X*1000,Y)
    %try
    %    title(strcat(parname,' histogram for ',wavname))
    %catch MEtitle
    %    disp(class(wavname))
    %    disp(strcat(parname,' histogram for ',wavname))
    title(strcat(parname,' histogram'))
    %end
    xlabel([xaxlabel ' (N=' num2str(length(values)) ')'])
    ylabel ('Count')
    try
        saveas(gcf, plotoutname);
    catch MEplotname
        disp(plotoutname)
        rethrow(MEplotname)
    end
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
