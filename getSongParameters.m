function pulsetrains = getSongParameters(data, peakIdxGroup, isNoise, options)
    %processing script downstream of assignDataToTemplates
    %pulsetrains should be a structure containing data
    %on each pulse train (location of all pulses and their CF,
    %all IPI, PTL, PPB)
    %necessary options: fs, distance separating pulses 
    %to be considered a new pulse train
    %reporting pulses, ipi, and ptl in seconds, cf in Hz
    signalPeakIdx = getSignalPeakIdx(peakIdxGroup, isNoise);
    ts = signalPeakIdx/options.fs; %convert to seconds
    ipiall = diff(ts);
    isConnected = ipiall <= options.maxIPI;
    CC = bwconncomp(isConnected);
    pulses = cell(1, CC.NumObjects);
    cf = cell(1, CC.NumObjects);
    ipi = cell(1, CC.NumObjects);
    numPulses = zeros(1, CC.NumObjects);
    trainLengths = zeros(1, CC.NumObjects);
    for i=1:CC.NumObjects
        numPulses(i) = length(CC.PixelIdxList{i});
        trainLengths(i) = ts(CC.PixelIdxList{i}(end)+1) - ts(CC.PixelIdxList{i}(1));
        pulses{i} = [ts(CC.PixelIdxList{i}) ts(CC.PixelIdxList{i}(end)+1)];
        ipi{i} = diff(pulses{i});
        %carrier frequency estimation will require some distance around
        %peak?
        %cf{i} = getCarrierFrequency(pulses{i});
    end
    pulsetrains = struct('pulses',pulses,'ipi',ipi,'cf',cf,'numPulses',numpulses,...
        'trainLengths',trainLengths);
end