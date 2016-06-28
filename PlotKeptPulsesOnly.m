function PlotKeptPulsesOnly(wav_file, whichsignal, segopts, outdir, diffThreshold)
    %Plot only the pulses that are included in IPI calculations
    %Read in the options used in the run (or use defaults)
    if exist(segopts,'file') == 2
        load(segopts);
    end
    if exist('minpulse','var') ~= 1
        minpulse = 10;
    end
    if exist('maxIPI','var') ~= 1
        maxIPI = 0.2;
    end
    if exist('sigmaThreshold','var') ~= 1
        sigmaThreshold = 1.1;
    end
    if exist('fs','var') ~= 1
        fs = 6000;
    end
    if exist('analyzerdir','var') ~= 1
        analyzerdir = '/Users/wynnmeyer/repos/FlySongClusterSegment/';
    end
    addpath(analyzerdir);
    %Load data file (should contain dfilt)
    matoutname = strcat(wav_file,'_data');
    df=load(strcat(matoutname,'.mat'));
    %Read in the pulse assignments
    [~,wavbase,ext] = fileparts(wav_file);
    origoutname = strcat(outdir,'/',wavbase,ext,'_datasigma',num2str(sigmaThreshold));
    outname = strcat(origoutname,'mp',num2str(minpulse));
    %outname = strcat(outdir,'/',wavbase,ext,'_data');
    dataoutname = strcat(outname,'signal',sprintf('%d',whichsignal), ...
        'maxIPI',num2str(maxIPI),'assigned.mat');
    load(dataoutname); %contains peakIdxGroup
    sprintf('Length of peakIdxGroup: %d\n',length(peakIdxGroup))
    %Filter pulse assignments to only those peaks included for IPI calculations 
    %Include only signal peaks
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);
    sprintf('Length of signalPeakIdx: %d\n',length(signalPeakIdx))
    %Eliminate ones with spacing > maxIPI
    wall = diff(signalPeakIdx)./fs;
    isConnected = wall <= maxIPI;
    CC = bwconncomp(isConnected);
    %Eliminate ones in trains < minpulse pulses
    tokeep = [];
    numPulses = zeros(CC.NumObjects,1);
    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        %trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        if numPulses(i) > (minpulse - 1)
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            tokeep = [tokeep pulsestoadd];
        end
    end
    %Zero out idx from each template that are not in tokeep
    for p = 1:length(peakIdxGroup)
        Lia = ismember(peakIdxGroup{p}, tokeep);
        sprintf('# of peaks kept from template %d: %d\n',p,sum(Lia))
        peakIdxGroup{p} = peakIdxGroup{p}(Lia);
    end
    %Write out new peakIdxGroup
    save(strcat(outname,'filteredpeakIdxGroup.mat'),'peakIdxGroup')
    %Run makePeakPlot
    try
        makePeakPlot(df.dfilt, peakIdxGroup, whichsignal);
        savefig(strcat(outname,'dT',num2str(diffThreshold),'FilteredSignalColored.fig'));
    catch ME
        path
        rethrow(ME)
    end
end
