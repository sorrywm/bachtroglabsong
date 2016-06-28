function FixBaselinesAndPlot(odfilein, basefilename, whichsignal, options,...
    diffThreshold, sigmaThreshold)
    %wrapper to reassignTemplateBaselines
    %odfilein: outputData from initial createTemplates run
    %basefilename: base filename of .mat file with song data (<wavfile>_data)
    %whichsignal: which templates are signal
    %options: optional options file
    %diffThreshold: width of templates (find using templates?)
    %sigmaThreshold: multiple of sd to use as noise threshold
    %set options:
    if exist(options,'file') == 2
        wmoptions = load(options);
    else
        fprintf('The options file %s does not exist. Using default options.\n',options)
        tpd = min(diffThreshold*2-1,50);
        wmoptions = struct('fs',6000,'diffThreshold',diffThreshold,...
        'template_pca_dimension',tpd,'use_likelihood_threshold',0,...
        'min_template_size',5,'sigmaThreshold',sigmaThreshold,...
        'segmenterdir','/Users/wynnmeyer/repos/FlySongClusterSegment/');        
    end
    addpath(wmoptions.segmenterdir);
    wmoptions.setAll = false;
    wmoptions = makeDefaultOptions(wmoptions); 
    load(odfilein); %must contain outputData
    %make isNoise from outputData.templates
    isNoise = true(size(outputData.templates));
    isNoise(whichsignal) = false;
    outputData = reassignTemplateBaselines(outputData, isNoise, wmoptions);
    %outputData.isNoise
    odfileout=strcat(basefilename,'newoutputData.mat');
    save(odfileout,'outputData');
    %add: re-assign, count peaks, and plot
    %load in dfilt
    song=load([basefilename '.mat']); %should have dfilt
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks] = ...
                     assignDataToTemplates(song.dfilt,outputData,wmoptions);
    sprintf('All peaks found after assignment: %d\n',length(allPeakIdx))
    signalpeakcount=0;
    for sp=1:length(whichsignal)
        signalpeakcount=signalpeakcount+length(peakIdxGroup{sp});
    end
    sprintf('Signal peaks found after assignment: %d\n',signalpeakcount)
    save(strcat(basefilename,'newassigned.mat'),'groupings','peakIdxGroup',...
    'likes','allPeakIdx','allNormalizedPeaks');
    makePeakPlot(song.dfilt, peakIdxGroup, 1:length(outputData.templates));
    savefig(strcat(basefilename,'newAllColored.fig'));
    makePeakPlot(song.dfilt, peakIdxGroup, whichsignal);
    savefig(strcat(basefilename,'newSignalColored.fig'));
end