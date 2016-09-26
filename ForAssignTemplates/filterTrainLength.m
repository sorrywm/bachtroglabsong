function [tokeep, numPulses, numPulses5pm, trainLengths, CC] = ...
    filterTrainLength(ts, ipiall, maxIPI, minpulse, signalPeakIdx)
    %Filter to include only pulses in trains of at least minpulse pulses
    %Separate? also split into male and female based on mean IPI.
    isConnected = ipiall <= maxIPI;
    CC = bwconncomp(isConnected);
    tokeep = [];
    %Track pulses per burst and pulse train length.
    numPulses = zeros(CC.NumObjects,1);
    numPulses5pm = [];
    trainLengths = [];

    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        if numPulses(i) > (minpulse - 1)
            trainLengths = [trainLengths ts(CC.PixelIdxList{i}(end)+1) ...
                - ts(CC.PixelIdxList{i}(1))];
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) ...
                signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            tokeep = [tokeep pulsestoadd];
            numPulses5pm = [numPulses5pm numPulses(i)];
        end
    end
end