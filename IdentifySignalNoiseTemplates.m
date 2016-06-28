function IdentifySignalNoiseTemplates(peaksassigned,categorytimes,outfile)
    %Use initial assignment of templates,
    %in combination with times known to represent signal and noise
    %to evaluate templates by estimating, for each template,
    %the number of pulses within signal regions and within noise regions
    %read in csv file with signal/noise regions
    cattimetable = readtable(categorytimes);
    %get initial peak assignments
    prelimdata = load(peaksassigned);
    %add one column per template?
    for c=1:length(prelimdata.peakIdxGroup)
        cattimetable.(['T', num2str(c)]) = zeros(height(cattimetable),1);
    end
    %make new counters: signalpeaks, noisepeaks
    templates = (1:length(prelimdata.peakIdxGroup))';
    signalpeaks = zeros(length(prelimdata.peakIdxGroup),1);
    noisepeaks = zeros(length(prelimdata.peakIdxGroup),1);
    %loop over peakIdxGroup
    for g=1:length(prelimdata.peakIdxGroup)
        %loop over time intervals
        for t=1:height(cattimetable)
            if t==1
                timeint = {1, cattimetable.cumtime(1)};
            else
                timeint = {cattimetable.cumtime(t-1)+1,cattimetable.cumtime(t)};
            end
            %for each interval, determine if signal/noise
            issig = 0;
            if strcmp(cattimetable.category(t), 'signal')
                issig = 1;
            end
            %count the # of peaks for this template
            numpeaks = sum(prelimdata.peakIdxGroup{g} >= timeint{1} & ...
                prelimdata.peakIdxGroup{g} < timeint{2});
            %assign to template-specific column?
            cattimetable.(['T', num2str(g)])(t) = numpeaks;
            %add to signalpeaks or noisepeaks
            if issig == 1
                signalpeaks(g) = signalpeaks(g) + numpeaks;
            else
                noisepeaks(g) = noisepeaks(g) + numpeaks;
            end
        end
    end
    %write csv: template, signalpeaks, noisepeaks
    temptable = table(templates, signalpeaks, noisepeaks);
    writetable(temptable, outfile);
    %Additionally, add to existing csv (1 columns for each template)?
    writetable(cattimetable, [categorytimes 'withtemplates.csv']);
end