function signalPeakIdx = getSignalPeakIdx(peakIdxGroup, isNoise)
    %Get peakIdx for all signal peaks.
    whichsignal = find(isNoise==0)';
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);
end