function signalPeakIdx = getPeaksForROC(wavfile,outputData,smoothnoise)
    %match smoothingLength_noise to that used for template generation
    %assign templates for validation set
    %output signalPeakIdx (to check against numbers in signal/noise
    %regions)
    filtcut = 200;
    [d,fs] = audioread(wavfile); %assume fs is the same
    dfilt = tybutter(d,filtcut,fs,'high');
    load(outputData);
    options.fs = fs;
    options.smoothingLength_noise = smoothnoise; %default 
    outputData = reassignTemplateBaselines(outputData, isNoise, options);
    [~,peakIdxGroup,~,~,~,~] = ...
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