function CreateAndAssignTemplates(trainfile,valfile,ampthresh,smoothnoise)
    %Generate templates using the training file
    %Add any paths first
    %See whether filter can be changed from high-pass to band-pass
    %Still working out: Save template histogram and t-SNE plots separately
    [outdir1,outbase1,~] = fileparts(trainfile);
    outdir1 = [outdir1 '/templates_' outbase1];
    if exist(outdir1,'dir') ~= 7
        mkdir(outdir1);
    end
    outbase1 = [outbase1 '_at' num2str(ampthresh) '_sn' num2str(smoothnoise)];
    [d,fs] = audioread(trainfile);
    dfilt = tybutter(d,200,fs,'high'); %modify?
    options.fs = fs;
    options.amplitude_threshold = ampthresh; %default .9
    options.smoothingLength_noise = smoothnoise; %default 4
    %new: try Gordon's t-SNE analysis
    options.run_tsne = true;
    [outputData,allPeakIdx,allNormalizedPeaks,peakAmplitudes,isNoise,allScores,...
        options] = createTemplates(dfilt,options);
    %creates 2 plots - save both
    savefig(fullfile(outdir1,[outbase1 '_tSNEPlot.fig']));
    close;
    savefig(fullfile(outdir1,[outbase1 '_TemplateHistograms.fig']));
    close;
    save(fullfile(outdir1,[outbase1 '_outputCreateTemplates.mat']), 'outputData',...
        'allPeakIdx','allNormalizedPeaks','peakAmplitudes','isNoise','allScores',...
        'options');
    %Now assign the validation data to templates
    [outdir2,outbase2,~] = fileparts(valfile);
    outdir2 = [outdir2 '/output_' outbase2];
    if exist(outdir2,'dir') ~= 7
        mkdir(outdir2);
    end
    outbase2 = [outbase2 '_at' num2str(ampthresh) '_sn' num2str(smoothnoise)];
    [d2,fs2] = audioread(valfile);
    dfilt2 = tybutter(d2,200,fs2,'high'); %modify?
    options.fs = fs2;
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,noiseThreshold] = ...
                     assignDataToTemplates(dfilt2,outputData,options);
    save(fullfile(outdir2,[outbase2 '_outputAssignTemplates.mat']), 'groupings',...
        'peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','noiseThreshold');
    %Plot the templates
    makePeakPlot(dfilt2,peakIdxGroup,[1:length(peakIdxGroup)]);
    savefig(fullfile(outdir2,[outbase2 '_TemplatesAssigned.fig']));
end