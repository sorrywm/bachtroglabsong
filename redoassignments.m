function redoassignments(odfile, isNoise, newfilebase, dfiltfile,...
    categorytimes, diffThreshold, sigmaThreshold, noiseLevel)
    %set options
    fs = 6000;
    wmoptions = v2struct(fs, diffThreshold, sigmaThreshold, noiseLevel);
    %reassign template baselines
    load(odfile);
    outputData = reassignTemplateBaselines(outputData, isNoise);
    save([newfilebase 'outputData.mat'], 'outputData');
    %redo peak calling
    data=load(dfiltfile);
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks] = ...
                     assignDataToTemplates(data.dfilt,outputData,wmoptions);
    save([newfilebase 'assigned.mat'],'groupings','peakIdxGroup',...
    'likes','allPeakIdx','allNormalizedPeaks');
    makePeakPlot(data.dfilt, peakIdxGroup, 1:length(outputData.templates));
    savefig([newfilebase 'AllColored.fig']);
    %redo identification of signal and noise templates
    IdentifySignalNoiseTemplates([newfilebase 'assigned.mat'],...
        categorytimes,[newfilebase '.templates.csv'])
end