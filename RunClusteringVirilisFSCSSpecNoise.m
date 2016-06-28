function RunClusteringVirilisFSCSSpecNoise(wav_file, prevtempfile, whichsignal, ipiptl, segopts, outdir, doplots, remnoise, diffThreshold)
    %Modified 4/17/16: assume all templates not in whichsignal are noise
    %Modified 4/15/16: use FlySongClusterSegment version of assignDataToTemplates
    %To do: Save pulse train parameters together so cutoff can be adjusted
    %To do: Load previously assigned data if available
    %To do: Save output files in a different folder.
    %Alternative: Move files after creating them (in bash wrapper).
    %New: makes sigmaThreshold (for multiple of noise to consider signal) 1.5
    %     if segopts doesn't exist, 2 if it does (for back-compatibility)
    %New: allow specification of minimum # pulses (minpulse) in segopts
    %New: allow specification of start and end song time (song_range) in segopts
    %New: reads in fs (sampling frequency) from audio file
    %Now uses addpath rather than changing directories. 
    %If any issues, check if multiple paths have same script names).
    %Added option: ipiptl can be 'IPI','PTL', or 'both'
    %PTL/PPB analysis now ONLY run with minpulse minimum (not all trains)
    %Optional: parameters can be saved separately for male and female (using 'femalecut'
    %for IPI threshold)
    %Template filename taken out of final filename (too long)
    %Adding option to remove noise peaks from empty channel.
    if nargin < 8
        remnoise = 'FALSE';
        if nargin < 7
            doplots = 'TRUE';
            if nargin < 6
                error('Must specify output directory!\n')
            end
        end
    end
    clearvars -except wav_file prevtempfile whichsignal ipiptl segopts outdir doplots remnoise diffThreshold;
    femalecut = 0.025; %test this... potentially add to opts
    numpulsemax = 100;
    pulsetrainmax = 1.5; %in seconds
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options),
        %domalefemale (T/F: analyze sexes separately?)
        if exist('sigmaThreshold','var')
            relvars = {'fs','diffThreshold','template_pca_dimension','sigmaThreshold'};
            wmoptions = load(segopts,relvars{:});
        else
            relvars = {'fs','diffThreshold','template_pca_dimension'};
            wmoptions = load(segopts,relvars{:});
            %wmoptions.sigmaThreshold = 2;
         end
    else
        %Modify the following to the location of your versions of these programs.
        %Alternatively, save these locations and load as segopts.
        analyzerdir = '../FlySongClusterSegment/';
        %plotanalyzerdir = '../fly_song_analyzer_032412/';
        plotanalyzerdir = '../FlySongClusterSegment/';
        segmenterdir = '../FlySongSegmenter/';
        chronuxdir = '../FlySongSegmenter/chronux/';
        butterdir = pwd;
        fs = 6000; %read from file?
        %diffThreshold = 20;
        %template_pca_dimension = 10;
        %sigmaThreshold = 1.1;
        sigmaThreshold = 4;
        baseline_quantile = 0.95;
        template_pca_dimension = min(50, 2*diffThreshold-1);
        wmoptions = struct('fs',fs,'template_pca_dimension',...
                           template_pca_dimension, 'sigmaThreshold',...
                           sigmaThreshold,'baseline_quantile',...
                           baseline_quantile); %changed baseline_quantile and sigmaThreshold
        filtcut=200;
        isshort='n';
        domalefemale='FALSE';
        minpulse = 10;
        save(segopts,'analyzerdir','plotanalyzerdir','segmenterdir','chronuxdir', ...
             'butterdir','fs','template_pca_dimension','sigmaThreshold', ...
             'filtcut','isshort','domalefemale','minpulse','baseline_quantile'); %save options file
    end

    sigmaThreshold = 4;
    wmoptions.sigmaThreshold = sigmaThreshold;
    template_pca_dimension = min(50, 2*diffThreshold-1);
    wmoptions.template_pca_dimension = template_pca_dimension;
    wmoptions.baseline_quantile = 0.95;
    addpath(segmenterdir,plotanalyzerdir,butterdir,chronuxdir);
    currentFolder = pwd;

    %Estimate runtime:
    tic;
    [~,wavbase,ext] = fileparts(wav_file);
    matoutname = strcat(wav_file,'_data');
    %origoutname = strcat(outdir,'/',wavbase,ext,'_data');
    origoutname = strcat(outdir,'/',wavbase,ext,'_datasigma',num2str(wmoptions.sigmaThreshold));
    if exist('song_range','var')==1
        if length(song_range) > 0
            matoutname = strcat(wav_file,num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
            origoutname = strcat(outdir,'/',wavbase,ext,num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
        end
    else
        song_range = [];
    end
    %New outname for all files using the minpulse cutoff
    if exist('minpulse','var')==0
        minpulse = 5;
    end
    %else
    outname = strcat(origoutname,'mp',num2str(minpulse));
    %end

    splittempname = strsplit(prevtempfile,'/');
    newtempoutname = splittempname{length(splittempname)};
    %Make maxIPI a part of opts file?
    maxIPI = 0.2; %maximum IPI before a new bout is formed (in s)

    %Load in previously computed templates.
    fprintf('Loading previous templates: %s.\n', prevtempfile);
    load(prevtempfile);

    %test whether relevant files already exist
    wout = strcat(outname,'dT',num2str(diffThreshold), ...
            'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist');
    ptlout = strcat(outname,'dT',num2str(diffThreshold), ...
            'signal', sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI));
    ipifiles = {strcat(wout,'.txt') strcat(wout,'all.mat') strcat(wout,'allmin5pulse.txt')};
    mfipifiles = {strcat(wout,'male.mat') strcat(wout,'female.mat') ...
                    strcat(wout,'malemin5pulse.txt') strcat(wout,'femalemin5pulse.txt')};
    ptlfiles = {strcat(ptlout,'allPTL.txt') strcat(ptlout,'allPPB.txt') ...
                strcat(ptlout,'allPPB5pm.txt') strcat(ptlout,'allPTL_PPBdata.mat')};
    mfptlfiles = {strcat(ptlout,'femalePTL.txt') strcat(ptlout,'malePTL.txt') ...
               strcat(ptlout,'femalePPB.txt') strcat(ptlout,'malePPB.txt')};
    plotfiles = {strcat(origoutname,'dT',num2str(diffThreshold),'AllColored.fig') ...
                 strcat(origoutname,'dT',num2str(diffThreshold),'SignalColored.fig')};
    ipiplotfiles = {strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesIPIHist.jpg') strcat(outname, ...
                'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesIPIHist5pm.jpg')};
    mfipiplotfiles = {strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesFemaleIPIHist5pm.jpg') strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesMaleIPIHist5pm.jpg')};
    ptlplotfiles = {strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesPPBHist5pm.jpg') strcat(outname, ...
                'FiltdT',num2str(diffThreshold),'SignalTemplatesPTLHist5pm.jpg')};
    mfptlplotfiles = {strcat(outname,'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesFemalePPBHist5pm.jpg') strcat(outname,'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesMalePPBHist5pm.jpg') strcat(outname, ...
                    'FiltdT',num2str(diffThreshold),'SignalTemplatesFemalePTLHist5pm.jpg') strcat(outname, ...
                    'FiltdT',num2str(diffThreshold),'SignalTemplatesMalePTLHist5pm.jpg')};
    runcode = 0;
    if strcmp(doplots, 'TRUE')
        if strcmp(ipiptl, 'IPI') == 1 || strcmp(ipiptl, 'both') == 1
            plotfiles = [plotfiles ipiplotfiles];
            if strcmp(domalefemale, 'TRUE')
                plotfiles = [plotfiles mfipiplotfiles];
            end
        end
        if strcmp(ipiptl, 'PTL') == 1 || strcmp(ipiptl, 'both') == 1
            plotfiles = [plotfiles ptlplotfiles];
            if strcmp(domalefemale, 'TRUE')
                plotfiles = [plotfiles mfptlplotfiles];
            end
        end
        for pf = 1:length(plotfiles)
            if exist(plotfiles{pf}, 'file') ~=2
                fprintf('plotfile %s does not exist\n',plotfiles{pf});
                runcode = 1;
            end
        end
    end
    if strcmp(ipiptl, 'IPI') == 1 || strcmp(ipiptl, 'both') == 1
        if strcmp(domalefemale,'TRUE')
            ipifiles = [ipifiles mfipifiles];
        end
        for ifile = 1:length(ipifiles)
            if exist(ipifiles{ifile}, 'file') ~= 2
                fprintf('ipifile %s does not exist\n',ipifiles{ifile});
                runcode = 1;
            end
        end
    end
    if strcmp(ipiptl, 'PTL') == 1 || strcmp(ipiptl, 'both') == 1
        if strcmp(domalefemale,'TRUE')
            ptlfiles = [ptlfiles mfptlfiles];
        end
        for ptfile = 1:length(ptlfiles)
            if exist(ptlfiles{ptfile}, 'file') ~= 2
                fprintf('ptfile %s does not exist\n',ptlfiles{ptfile});
                runcode = 1;
            end
        end
    end
    if runcode == 0
        fprintf('All analysis files for %s exist on %s\n',wav_file,date);
        exit
    end

    %First, check whether data already exists:
    %If d exists but dfilt does not, just filter d.
    %If data does not exist, grab the wav file.
    %If the wav file does not exist, error out.
    if exist(strcat(matoutname,'.mat'),'file') == 2
        d = load(strcat(matoutname,'.mat'));
        if isfield(d,'dfilt') == 0
            fprintf('Grabbing song from wav file to filter and resave: %s.\n', wav_file);
            if exist(wav_file) == 2
                if ~isempty(song_range)
                   [song,newfs] = audioread(wav_file,song_range);
                else
                   [song,newfs] = audioread(wav_file);
                end
                %Save this file
                d=song;
                %cd(butterdir);
                dfilt = tybutter(d,filtcut,newfs,'high');
                fs = newfs;
                save(strcat(matoutname,'.mat'),'d','dfilt','fs');
            else
                error('Wav file does not exist: %s.\n', wav_file);
            end
        else
            dfilt=d.dfilt;
            if isfield(d,'fs') == 1
                fs = d.fs;
            end
        end
    else   
        %Generate a data file from the .wav file
        fprintf('Grabbing song from wav file %s.\n', wav_file);
        if ~isempty(song_range)
            [song,newfs] = audioread(wav_file,song_range);
        else
            [song,newfs] = audioread(wav_file);
        end
        %Save this file
        d=song;
        %cd(butterdir);
        dfilt = tybutter(d,filtcut,newfs,'high');
        fs = newfs;
        save(strcat(matoutname,'.mat'),'d','dfilt','fs');
    end
    if fs ~= wmoptions.fs
        %subsample dfilt to equalize the sampling frequency
        fprintf(['Sub-sampling %s (initial sampling frequency %d Hz) to ' ...
                 'match sampling frequency of templates (%d Hz)\n'], ...
                 wav_file,fs,wmoptions.fs);
        [P,Q] = rat(wmoptions.fs/fs);
        dfilt = resample(dfilt,P,Q);
    end
    %Check that noise templates are provided.
    if length(whichsignal) > length(newtemplates) || length(whichsignal) == length(newtemplates)
        %fprintf('Keeping all signals: %s.\n', num2str(length(newtemplates)));
        error('No noise templates provided (signal from %s: %s)\n',prevtempfile,strcat(num2str(whichsignal)));
    end
    %Set isnoise to all templates not in whichtemplates.
    alltemp = [1:length(newtemplates)];
    isnoise = setdiff(alltemp,whichsignal);

    %Assign data to templates if not already done.
    %dataoutname = strcat(outname,newtempoutname,'signal',s %dataoutname = strcat(outname,newtempoutname,'signal',sprintf('%d',whichsignal), ...
    dataoutname = strcat(outname,'signal',sprintf('%d',whichsignal), ...
        'maxIPI',num2str(maxIPI),'assigned.mat');
    if exist('dataoutname','file') ~= 2
        fprintf('Assigning data to templates from %s.\n', prevtempfile);
        try
            %[groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,...
            %coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
            [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,...
            coeffs,projStds,baselines] = assignDataToTemplates(dfilt,newtemplates,isnoise,wmoptions);
        catch MEadtt
            display(path)
            rethrow(MEadtt)
        end
        %Save these variables... including which templates were called signals.
        save(dataoutname,'groupings','peakIdxGroup','likes','allPeakIdx', ...
            'allNormalizedPeaks','coeffs','projStds','whichsignal');
    else
        load(dataoutname)
    end

    %Plot all templates and just signal templates.
    if strcmp(doplots,'TRUE')
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        %savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'AllColored.fig'));
        savefig(strcat(origoutname,'dT',num2str(diffThreshold),'AllColored.fig')),
        makePeakPlot(dfilt, peakIdxGroup, whichsignal);
        %savefig(strcat(outname,newtempoutname,'dt',num2str(diffThreshold),'SignalColored.fig'));
        savefig(strcat(origoutname,'dT',num2str(diffThreshold),'SignalColored.fig'));
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

    %Remove noise peaks if requested.
    if strcmp(remnoise,'TRUE')
        %Determine filename for noise file.
        try
            noisefile = findNoiseFile(wavbase,whichsignal);
        catch ME
            error('remnoise improperly set: %s\n',remnoise)
        end
        if length(noisefile) > 0
            %Load noise file.
            noise = load(noisefile);
            %Remove peaks in signalPeakIdx that are also in the noise file.
            innoise = intersect(signalPeakIdx, noise.signalPeakIdx);
            signalPeakIdx = setdiff(signalPeakIdx, noise.signalPeakIdx);
            %Change outname to indicate that noise peaks have been removed.
            outname = strcat(outname,'remnoise');
            %Print number of peaks removed.
            fprintf('%d noise peaks removed from %s, leaving %d signal peaks.\n',length(innoise),wavbase,length(signalPeakIdx))
        end
    end

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

    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        %trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        if numPulses(i) > (minpulse - 1)
            trainLengths = [trainLengths ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1))];
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
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
            maxIPI, 'all', wout, minpulse);
        if strcmp(domalefemale,'TRUE')
            [tokeepmale, w5male] = sortAndSavePulseTrains(tokeepmale, wmoptions.fs, ...
                maxIPI, 'male', wout, minpulse);
            [tokeepfemale, w5female] = sortAndSavePulseTrains(tokeepfemale, wmoptions.fs, ...
                maxIPI, 'female', wout, minpulse);
        end
        if strcmp(doplots, 'TRUE')
            %New code for plotting histograms
            plotParameterHist(w, 100, 'IPI', wavbase, 'Inter-pulse interval (IPI), in ms', ...
                strcat(outname,'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesIPIHist.jpg'));
        
            %also plot just 5-pulse IPIs
            plotParameterHist(w5, 100, '5-pulse minimum IPI', wavbase, ...
                'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                'FiltdT',num2str(diffThreshold), ...
                'SignalTemplatesIPIHist5pm.jpg'));

            if strcmp(domalefemale,'TRUE')
                %Plot female and male IPIs separately.
                plotParameterHist(w5female, 100, '5-pulse minimum IPI female', wavbase, ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesFemaleIPIHist5pm.jpg'));
                plotParameterHist(w5male, 100, '5-pulse minimum IPI male', wavbase, ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'FiltdT',num2str(diffThreshold), ...
                    'SignalTemplatesMaleIPIHist5pm.jpg'));
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
        ipicut, pulselabel, pulseoutfile, minpulse);
    pulses = sort(unsortedpulses);
    w5all = diff(pulses)./sampfreq;
    w5 = w5all(w5all <= ipicut);
    fprintf('Number of  %s pulse trains with at least %d pulses: %s\n', ...
        pulselabel, minpulse, num2str(length(w5)))
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

function noisefile = findNoiseFile(filename,wsignal)
    %find the noise templates filename based on the outname
    %e.g.: 2015-07-09_Channel_32_Noise.wav_datasignal1456789101112signalpeaks.mat
    %modify for use with a/b names
    noisedir = '/global/scratch/wynn/ClusteringOutputPerSpecies/ForNoise';
    noisefile = [];
    sf = strsplit(filename,'_');
    ab = [strfind(sf{3},'a') strfind(sf{3},'b')];
    if length(ab) == 0
        ss = strcat(noisedir, '/', sf{1}, '*', sprintf('%d',wsignal), '*');
        nfs = dir(ss);
        if length(nfs) == 1
            noisefile = strcat(noisedir,'/',nfs(1).name);
        else
            fprintf('Noise file for %s (%s) not found.\n',filename,ss);
        end
    else
        fprintf('%s needs a corresponding a/b noise file.',filename);
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
