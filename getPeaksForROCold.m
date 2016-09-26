function signalPeakIdx = getPeaksForROCold(wavfile,outputData,whichsignal,baseline_quantile)
    %reassign baselines using baseline_quantile
    %assign templates for validation set
    %output signalPeakIdx (to check against numbers in signal/noise
    %regions)
    filtcut = 200;
    [d,fs] = audioread(wavfile); %assume fs is the same
    dfilt = tybutter(d,filtcut,fs,'high');
    load(outputData);
    options.sigmaThreshold = 1.1;
    options.baseline_quantile = baseline_quantile;
    isNoise = true(size(outputData.templates));
    isNoise(whichsignal) = false;
    outputData = reassignTemplateBaselines(outputData, isNoise, options);
    [~,peakIdxGroup,~,~,~] = ...
                assignDataToTemplates(dfilt,outputData,options);
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);
end