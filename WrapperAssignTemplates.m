function WrapperAssignTemplates(wav_file, prevtempfile, segopts, ...
    outdir, outsuff, doplots, ipiptl)
    %Can probably further condense section saving output and plotting (155
    %- 311)
    if nargin < 7 || isempty(ipiptl)
        ipiptl = 'both';
    end
    if nargin < 6 || isempty(doplots)
        doplots = 'TRUE';
    end
    if nargin < 5 || isempty(outsuff)
        outsuff = segopts;
    end
    if nargin < 4 || isempty(outdir)
        outdir = '../';
    end
    if nargin < 3 || isempty(segopts)
        segopts = [];
    end
    if nargin < 2 || isempty(prevtempfile)
        error('Must specify an outputData file with template data\n');
    end
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the options variables (below) saved
        wmoptions = load(segopts);
    else
        segmenterdir = '../FlySongClusterSegment/';
        fs = 6000; %standardized across songs
        sigmaThreshold = 1;
        baseline_quantile = 0.95;
        diffThreshold = 30;
        template_pca_dimension = min(50, 2*diffThreshold-1);
        filtcut=200;
        domalefemale='TRUE';
        minpulse = 5;
        femalecut = 0.025; %IPI threshold (in s) for separating female from male song
        numpulsemax = 100;
        pulsetrainmax = 1.5; %in seconds
        maxIPI = 0.2; %maximum IPI before a new bout is formed (in s)
        song_range = [];
        noiseLevel = 0;
        minNoiseLevel = 0.04;
        if isempty(segopts)
            fprintf('Saving default options: %s.\n', [outdir '/' outsuff '.opts.mat']);
            save([outdir '/' outsuff '.opts.mat'],'segmenterdir','fs',...
                'sigmaThreshold','baseline_quantile','diffThreshold',...
                'template_pca_dimension','filtcut','domalefemale','minpulse',...
                'femalecut','numpulsemax','pulsetrainmax','maxIPI','song_range',...
                'noiseLevel','minNoiseLevel');
            wmoptions = load([outdir '/' outsuff '.opts.mat']);
        else
            fprintf('Saving default options: %s.\n', segopts);
            %Change the following so as not to save wav_file, etc.
            save(segopts,'segmenterdir','fs',...
                'sigmaThreshold','baseline_quantile','diffThreshold',...
                'template_pca_dimension','filtcut','domalefemale','minpulse',...
                'femalecut','numpulsemax','pulsetrainmax','maxIPI','song_range',...
                'noiseLevel','minNoiseLevel'); %save options file
            wmoptions = load(segopts);
        end
    end

    addpath(genpath(segmenterdir));

    %Estimate runtime:
    tic;
    [~,wavbase,ext] = fileparts(wav_file);
    matoutname = strcat(wav_file,'_data');
    outname = strcat(outdir,'/',wavbase, '_', outsuff);
    dataoutname = strcat(outname,'assigned.mat');
    wout = strcat(outname,'IPIdist');
    if exist('song_range','var')==1
        if length(song_range) > 0
            matoutname = strcat(wav_file,num2str(song_range(1)),'-',...
                num2str(song_range(2)),'_data');
            outname = strcat(outdir,'/',wavbase,ext,num2str(song_range(1)),...
                '-',num2str(song_range(2)),'_',outsuff);
        end
    end

    %Load in previously computed templates.
    fprintf('Loading outputData file: %s.\n', prevtempfile);
    load(prevtempfile);

    %First, check whether data already exists:
    if exist(strcat(matoutname,'.mat'),'file') == 2
        fprintf('Grabbing song from data file %s.\n', [matoutname '.mat']);
        d = load(strcat(matoutname,'.mat'));
        %If d exists but dfilt does not, just filter d.
        if isfield(d,'dfilt') == 0
            fprintf('Grabbing song from wav file to filter and resave: %s.\n', ...
                wav_file);
            if exist(wav_file,'file') == 2
                if ~isempty(song_range)
                   [d,fs] = audioread(wav_file,song_range);
                else
                   [d,fs] = audioread(wav_file);
                end
                %Save this file
                dfilt = tybutter(d,filtcut,fs,'high'); %remove? implemented in FSCS
                save(strcat(matoutname,'.mat'),'d','dfilt','fs');
             %If the wav file does not exist, error out.
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
        %If data does not exist, grab the wav file.
        fprintf('Grabbing song from wav file %s.\n', wav_file);
        if ~isempty(song_range)
            [d,fs] = audioread(wav_file,song_range);
        else
            [d,fs] = audioread(wav_file);
        end
        %Save this file
        dfilt = tybutter(d,filtcut,fs,'high');
        save(strcat(matoutname,'.mat'),'d','dfilt','fs');
    end
    if fs ~= wmoptions.fs
        %subsample dfilt to equalize the sampling frequency
        dfilt = fixSamplingFrequency(dfilt, fs, wmoptions.fs);
    end

    %Assign data to templates if not already done.
    if exist(dataoutname,'file') ~= 2 %change this if not writing output?
        fprintf('Assigning data to templates from %s.\n', prevtempfile);
            [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks] = ...
                assignDataToTemplates(dfilt,outputData,wmoptions);
        %Save these variables
        save(dataoutname,'groupings','peakIdxGroup','likes','allPeakIdx', ...
            'allNormalizedPeaks');
    else
        load(dataoutname)
    end

    %Plot all templates and just signal templates.
    if strcmp(doplots,'TRUE')
        makePeakPlot(dfilt, peakIdxGroup, [1:length(outputData.isNoise)]);
        savefig(strcat(outname,'AllColored.fig')),
        makePeakPlot(dfilt, peakIdxGroup, find(outputData.isNoise==0)');
        savefig(strcat(outname,'SignalColored.fig'));
    end
    
    %Compute and plot IPI.

    %Get peakIdx for all signal peaks.
    signalPeakIdx = getSignalPeakIdx(peakIdxGroup,outputData.isNoise);

    %Get IPI.
    [wall, wfilt] = calculateIPI(signalPeakIdx, maxIPI, wmoptions.fs);
    peaktimes = signalPeakIdx./wmoptions.fs; %necessary?
    
    %Filter to include only pulses in trains of at least minpulse pulses:
    [tokeep, numPulses, numPulses5pm, trainLengths, CC] = ...
    filterTrainLength(peaktimes, wall, maxIPI, minpulse, signalPeakIdx);

    %New: also split into male and female based on mean IPI.
    if strcmp(domalefemale,'TRUE')
        [tokeepmale, numpulsesmale, trainlengthsmale, tokeepfemale, numpulsesfemale,...
        trainlengthsfemale, CC] = mfFilterTrainLength(peaktimes, wall, maxIPI, minpulse, ...
        fs, femalecut, signalPeakIdx);
    end
    switch ipiptl
        case 'IPI'
            dlmwrite(strcat(wout,'.txt'),wall,'delimiter','\n');
            [tokeep, w5] = sortAndSavePulseTrains(tokeep, wmoptions.fs, ...
                maxIPI, 'all', wout, minpulse);
            if strcmp(domalefemale,'TRUE')
                [tokeepmale, w5male] = sortAndSavePulseTrains(tokeepmale, wmoptions.fs, ...
                    maxIPI, 'male', wout, minpulse);
                [tokeepfemale, w5female] = sortAndSavePulseTrains(tokeepfemale, wmoptions.fs, ...
                    maxIPI, 'female', wout, minpulse);
            end
            if strcmp(doplots, 'TRUE')
                plotParameterHist(wall, 100, 'IPI', 'Inter-pulse interval (IPI), in ms', ...
                    strcat(outname,'SignalTemplatesIPIHist.jpg'));
                plotParameterHist(w5, 100, '5-pulse minimum IPI', ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'SignalTemplatesIPIHist',num2str(minpulse),'pm.jpg'));
                if strcmp(domalefemale,'TRUE')
                    %Plot female and male IPIs separately.
                    plotParameterHist(w5female, 100, '5-pulse minimum IPI female', ...
                        'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                        'SignalTemplatesFemaleIPIHist',num2str(minpulse),'pm.jpg'));
                    plotParameterHist(w5male, 100, '5-pulse minimum IPI male', ...
                        'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                        'SignalTemplatesMaleIPIHist',num2str(minpulse),'pm.jpg'));
                end
            end
        case 'PTL'
            dlmwrite(strcat(outname,'allPTL.txt'),trainLengths,'delimiter','\n');
            dlmwrite(strcat(outname,'allPPB.txt'),numPulses,'delimiter','\n');
            dlmwrite(strcat(outname,'allPPB5pm.txt'),numPulses5pm,'delimiter','\n');
            if strcmp(domalefemale,'TRUE')
                save(strcat(outname,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths', ...
                    'numpulsesfemale', 'numpulsesmale', 'trainlengthsfemale', 'trainlengthsmale');
                %Also save all 5-pulse min values to text files
                dlmwrite(strcat(outname,'femalePTL.txt'),trainlengthsfemale,'delimiter','\n');
                dlmwrite(strcat(outname,'malePTL.txt'),trainlengthsmale,'delimiter','\n');
                dlmwrite(strcat(outname,'femalePPB.txt'),numpulsesfemale,'delimiter','\n');
                dlmwrite(strcat(outname,'malePPB.txt'),numpulsesmale,'delimiter','\n');
            else
                save(strcat(outname,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths');
            end
            if strcmp(doplots,'TRUE')
                %intnumPulses = numPulses(numPulses < numpulsemax);
                intnumPulses = numPulses5pm(numPulses5pm < numpulsemax);
                plotParameterHist(intnumPulses/1000, 50, 'PPB', 'Pulses per burst (PPB)', ...
                    strcat(outname,'SignalTemplatesPPBHist',num2str(minpulse),'pm.jpg'));

                inttrainLengths = trainLengths(trainLengths < pulsetrainmax);
                plotParameterHist(inttrainLengths, 50, 'PTL', ...
                    'Pulse Train Length (PTL), in ms', strcat(outname, ...
                    'SignalTemplatesPTLHist',num2str(minpulse),'pm.jpg'));

                if strcmp(domalefemale,'TRUE')
                    %Plot male and female separately.
                    intnumpulsesfemale = numpulsesfemale(numpulsesfemale < numpulsemax);
                    plotParameterHist(intnumpulsesfemale, 50, 'PPB', 'Pulses per burst (PPB) female', ...
                        strcat(outname,...
                        'SignalTemplatesFemalePPBHist',num2str(minpulse),'pm.jpg'));

                    inttrainlengthsfemale = trainlengthsfemale(trainlengthsfemale < pulsetrainmax);
                    plotParameterHist(inttrainlengthsfemale, 50, 'PTL', ...
                        'Pulse Train Length (PTL) female, in ms', strcat(outname, ...
                        'SignalTemplatesFemalePTLHist',num2str(minpulse),'pm.jpg'));

                    intnumpulsesmale = numpulsesmale(numpulsesmale < numpulsemax);
                    plotParameterHist(intnumpulsesmale, 50, 'PPB', 'Pulses per burst (PPB) male', ...
                        strcat(outname,...
                        'SignalTemplatesMalePPBHist',num2str(minpulse),'pm.jpg'));

                    inttrainlengthsmale = trainlengthsmale(trainlengthsmale < pulsetrainmax);
                    plotParameterHist(inttrainlengthsmale, 50, 'PTL', ...
                        'Pulse Train Length (PTL) male, in ms', strcat(outname, ...
                        'SignalTemplatesMalePTLHist',num2str(minpulse),'pm.jpg'));
                end
            end
        case 'both'
            dlmwrite(strcat(wout,'.txt'),wall,'delimiter','\n');
            [tokeep, w5] = sortAndSavePulseTrains(tokeep, wmoptions.fs, ...
                maxIPI, 'all', wout, minpulse);
            if strcmp(domalefemale,'TRUE')
                [tokeepmale, w5male] = sortAndSavePulseTrains(tokeepmale, wmoptions.fs, ...
                    maxIPI, 'male', wout, minpulse);
                [tokeepfemale, w5female] = sortAndSavePulseTrains(tokeepfemale, wmoptions.fs, ...
                    maxIPI, 'female', wout, minpulse);
            end
            if strcmp(doplots, 'TRUE')
                %plotParameterHist(values, hbreaks, parname, xaxlabel, plotoutname)
                plotParameterHist(wfilt, 100, 'IPI', 'Inter-pulse interval (IPI), in ms', ...
                    strcat(outname,'SignalTemplatesIPIHist.jpg'));
                plotParameterHist(w5, 100, '5-pulse minimum IPI', ...
                    'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                    'SignalTemplatesIPIHist',num2str(minpulse),'pm.jpg'));
                if strcmp(domalefemale,'TRUE')
                    %Plot female and male IPIs separately.
                    plotParameterHist(w5female, 100, '5-pulse minimum IPI female', ...
                        'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                        'SignalTemplatesFemaleIPIHist',num2str(minpulse),'pm.jpg'));
                    plotParameterHist(w5male, 100, '5-pulse minimum IPI male', ...
                        'Inter-pulse interval (IPI), in ms', strcat(outname, ...
                        'SignalTemplatesMaleIPIHist',num2str(minpulse),'pm.jpg'));
                end
            end
            dlmwrite(strcat(outname,'allPTL.txt'),trainLengths,'delimiter','\n');
            dlmwrite(strcat(outname,'allPPB.txt'),numPulses,'delimiter','\n');
            dlmwrite(strcat(outname,'allPPB5pm.txt'),numPulses5pm,'delimiter','\n');
            if strcmp(domalefemale,'TRUE')
                save(strcat(outname,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths', ...
                    'numpulsesfemale', 'numpulsesmale', 'trainlengthsfemale', 'trainlengthsmale');
                %Also save all 5-pulse min values to text files
                dlmwrite(strcat(outname,'femalePTL.txt'),trainlengthsfemale,'delimiter','\n');
                dlmwrite(strcat(outname,'malePTL.txt'),trainlengthsmale,'delimiter','\n');
                dlmwrite(strcat(outname,'femalePPB.txt'),numpulsesfemale,'delimiter','\n');
                dlmwrite(strcat(outname,'malePPB.txt'),numpulsesmale,'delimiter','\n');
            else
                save(strcat(outname,'allPTL_PPBdata.mat'),'CC','numPulses','numPulses5pm','trainLengths');
            end
            if strcmp(doplots,'TRUE')
                %intnumPulses = numPulses(numPulses < numpulsemax);
                intnumPulses = numPulses5pm(numPulses5pm < numpulsemax);
                plotParameterHist(intnumPulses, 50, 'PPB', 'Pulses per burst (PPB)', ...
                    strcat(outname,'SignalTemplatesPPBHist',num2str(minpulse),'pm.jpg'));

                inttrainLengths = trainLengths(trainLengths < pulsetrainmax);
                plotParameterHist(inttrainLengths, 50, 'PTL', ...
                    'Pulse Train Length (PTL), in ms', strcat(outname, ...
                    'SignalTemplatesPTLHist',num2str(minpulse),'pm.jpg'));

                if strcmp(domalefemale,'TRUE')
                    %Plot male and female separately.
                    intnumpulsesfemale = numpulsesfemale(numpulsesfemale < numpulsemax);
                    plotParameterHist(intnumpulsesfemale, 50, 'PPB', 'Pulses per burst (PPB) female', ...
                        strcat(outname, ...
                        'SignalTemplatesFemalePPBHist',num2str(minpulse),'pm.jpg'));

                    inttrainlengthsfemale = trainlengthsfemale(trainlengthsfemale < pulsetrainmax);
                    plotParameterHist(inttrainlengthsfemale, 50, 'PTL', ...
                        'Pulse Train Length (PTL) female, in ms', strcat(outname, ...
                        'SignalTemplatesFemalePTLHist',num2str(minpulse),'pm.jpg'));

                    intnumpulsesmale = numpulsesmale(numpulsesmale < numpulsemax);
                    plotParameterHist(intnumpulsesmale, 50, 'PPB', 'Pulses per burst (PPB) male', ...
                        strcat(outname,'SignalTemplatesMalePPBHist',num2str(minpulse),'pm.jpg'));

                    inttrainlengthsmale = trainlengthsmale(trainlengthsmale < pulsetrainmax);
                    plotParameterHist(inttrainlengthsmale, 50, 'PTL', ...
                        'Pulse Train Length (PTL) male, in ms', strcat(outname, ...
                        'SignalTemplatesMalePTLHist',num2str(minpulse),'pm.jpg'));
                end
            end
        otherwise
            fprintf('ipiptl variable must be IPI, PTL, or both: %s.\n', ipiptl);
    end
    toc;
end
