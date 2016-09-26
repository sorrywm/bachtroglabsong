function [pulses, ipis] = sortAndSavePulseTrains(unsortedpulses, sampfreq, ...
        ipicut, pulselabel, pulseoutfile, minpulse);
    pulses = sort(unsortedpulses);
    w5all = diff(pulses)./sampfreq;
    w5 = w5all(w5all <= ipicut);
    fprintf('Number of %s pulses in trains with at least %d pulses: %s\n', ...
        pulselabel, minpulse, num2str(length(w5)))
    save(strcat(pulseoutfile,pulselabel,'.mat'),'w5','w5all');
    dlmwrite(strcat(pulseoutfile,pulselabel,'min',num2str(minpulse),'pulse.txt'),w5,'delimiter','\n');
    ipis = w5;
end