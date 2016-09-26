function [ipiall, ipifilt] = calculateIPI(signalPeakIdx, maxIPI, fs)
    %Get IPI (in s).
    %ipifilt: IPI less than maxIPI
    ipiall = diff(signalPeakIdx)./fs;
    ipifilt = ipiall(ipiall <= maxIPI);
    fprintf('Number of IPI measurements less than %d ms: %d\n',...
        maxIPI*1000, length(ipifilt));
end