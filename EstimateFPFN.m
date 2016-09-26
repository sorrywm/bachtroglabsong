function [fn,fp] = EstimateFPFN(tempfile,alloutput,categorytimes)
    %Use initial assignment of templates,
    %in combination with times known to represent signal and noise
    %AND counts of peaks in signal regions
    %to evaluate outputData for certain parameters by estimating
    %the false negative rate (false negative/true positive)
    %and the false positive rate (false positive/true positive)
    %read in csv file with signal/noise regions and counts
    cattimetable = readtable(categorytimes);
    %just in case, sort the table by cumtime (necessary for next steps)
    cattimetable = sortrows(cattimetable,'cumtime','ascend');
    %get initial peak assignments
    prelimdata = load(alloutput, 'peakIdxGroup');
    %get isNoise
    tempdata = load(tempfile, 'isNoise');
    %name output file based on input file
    [outdir,outbase,~] = fileparts(alloutput);
    outbase = [outbase '_fpfn'];
    %add one column for observed counts
    cattimetable.calledpeaks = zeros(height(cattimetable),1);
    cattimetable.falsepositive = zeros(height(cattimetable),1);
    cattimetable.falsenegative = zeros(height(cattimetable),1);
    %loop over peakIdxGroup (only signal templates)
    %templates = (1:length(prelimdata.peakIdxGroup))';
    whichsignal = find(1-tempdata.isNoise);
    %loop over time intervals
    for t=1:height(cattimetable)
        if t==1
            timeint = {1, cattimetable.cumtime(1)};
        else
            timeint = {cattimetable.cumtime(t-1)+1,cattimetable.cumtime(t)};
        end
        numpeaks = 0;
        for g=1:length(whichsignal)
            %count the # of peaks for this template
            numpeaks = numpeaks + sum(prelimdata.peakIdxGroup{g} >= timeint{1} & ...
                prelimdata.peakIdxGroup{whichsignal(g)} < timeint{2});
        end
        %for each interval, determine if signal/noise
        issig = 0;
        if strcmp(cattimetable.category(t), 'signal')
            issig = 1;
        end
        %assign to template-specific column?
        cattimetable.calledpeaks(t) = numpeaks;
        %add to signalpeaks or noisepeaks
        if issig == 1
            if numpeaks > cattimetable.numpeaks(t)
                cattimetable.falsepositive(t) = numpeaks - cattimetable.numpeaks(t);
            else
                cattimetable.falsenegative(t) = cattimetable.numpeaks(t) - numpeaks;
            end
        else
            cattimetable.falsepositive(t) = numpeaks;
        end
    end
    %Save just false positive and false negative rates
    %Has to be calculated per interval.... 
    fp = sum(cattimetable.falsepositive)/sum(cattimetable.numpeaks);
    fn = sum(cattimetable.falsenegative)/sum(cattimetable.numpeaks);
    save(fullfile(outdir, [outbase '.mat']),'fp','fn');
    %Additionally, add to existing csv (1 columns for each template)?
    writetable(cattimetable, fullfile(outdir, ['PerIntervalPeaks' outbase '.csv']));
end