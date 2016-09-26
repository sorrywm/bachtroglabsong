function [tokeepmale, numpulsesmale, trainlengthsmale, tokeepfemale, numpulsesfemale,...
    trainlengthsfemale, CC] = mfFilterTrainLength(ts, ipiall, maxIPI, minpulse, fs, ...
    femalecut, signalPeakIdx)
    %Filter to include only pulses in trains of at least minpulse pulses
    %AND split into male and female based on median IPI.
    isConnected = ipiall <= maxIPI;
    CC = bwconncomp(isConnected);
    tokeepmale = [];
    tokeepfemale = [];
    %Track pulses per burst and pulse train length.
    numPulses = zeros(CC.NumObjects,1);
    numpulsesfemale = [];
    numpulsesmale = [];
    trainLengths = [];
    trainlengthsfemale = [];
    trainlengthsmale = [];

    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        if numPulses(i) > (minpulse - 1)
            pulsestoadd = [signalPeakIdx(CC.PixelIdxList{i}) ...
                signalPeakIdx(CC.PixelIdxList{i}(end)+1)];
            trainLengths = [trainLengths ts(CC.PixelIdxList{i}(end)+1) ...
                - ts(CC.PixelIdxList{i}(1))];
            medianipi = median(diff(pulsestoadd)./fs);
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