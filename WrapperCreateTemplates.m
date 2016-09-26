function WrapperCreateTemplates(wav_file, segopts, ...
    diffThreshold, sigmaThreshold, noiseLevel)
    %Reduce and change to fit new createTemplates input format
    %Set defaults for the following:
    fscsdir = '/Users/wynnmeyer/repos/FlySongClusterSegment/';
    filtcut=200;
    fs = 6000; %read from file?
    template_pca_dimension = min(diffThreshold*2-1,50);
    %Does reducing sigmaThreshold help with low amplitude peaks?
    relvars = {'fs','diffThreshold','template_pca_dimension','use_likelihood_threshold',...
        'baseline_threshold','min_template_size','sigmaThreshold'};
    %Replace the defaults if desired:
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:});
    else
        fprintf('The options file %s does not exist. Using default options.\n',segopts)
        use_likelihood_threshold=1;
        baseline_threshold=-90;
        min_template_size=5;
        wmoptions = v2struct(fs, diffThreshold, template_pca_dimension,...
            use_likelihood_threshold, baseline_threshold, min_template_size,...
            sigmaThreshold, noiseLevel);
        %save(segopts, 'fs','diffThreshold','template_pca_dimension',...
        %    'use_likelihood_threshold','baseline_threshold','min_template_size',...
        %    'sigmaThreshold');
    end
    
    addpath(genpath(fscsdir));
    [outdir,wavbase,~] = fileparts(wav_file);
    outname = strcat(wavbase,'_data');
    newtempoutname = strcat('TemplatesFrom',wavbase,'Filt');

    %Generate a data file from the .wav file
    %Read in origfs from this file (convert to fs if not equal) 
    %To do: Only run if _data file does not exist
    %From FlySongSegmenterWAV:
    fprintf('Grabbing song from wav file %s.\n', wav_file);
    [origsong, origfs] = audioread(wav_file);

    %Save this file?
    if origfs ~= fs
        d = fixSamplingFrequency(d,origfs,fs);
    else
        d = origsong;
    end

    dfilt = tybutter(d,filtcut,fs,'high');
    save(fullfile(outdir,[outname '.mat']),'d', 'dfilt');

    %To do: Shut down parallel pool after completion
    [outputData,allPeakIdx,allNormalizedPeaks,peakAmplitudes,isNoise,scores,options] = ...
                                createTemplates(dfilt,wmoptions);
    
    savefig(fullfile(outdir,strcat(outname,newtempoutname,'dT',...
        num2str(diffThreshold),'sT',num2str(sigmaThreshold),...
        'nL',num2str(noiseLevel),'TemplateHistograms.fig')));
    close;
    sprintf('All peaks found (new code): %d\n',length(allPeakIdx))
    
    save(fullfile(outdir,strcat(outname,newtempoutname,'dT',num2str(diffThreshold),...
        'sT',num2str(sigmaThreshold),'nL',num2str(noiseLevel),'.mat')),'outputData');
    save(fullfile(outdir,strcat(outname,'dT',num2str(diffThreshold),...
        'sT',num2str(sigmaThreshold),'nL',num2str(noiseLevel),'outputfromcreateTemplates.mat')),'allPeakIdx',...
        'allNormalizedPeaks','peakAmplitudes','isNoise','scores','options');
    sprintf('Current sigmaThreshold: %d\n',options.sigmaThreshold)
    sprintf('Current noiseLevel: %d\n',options.noiseLevel)
    %[groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
     [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks] = ...
                     assignDataToTemplates(dfilt,outputData,options);
    sprintf('All peaks found after assignment: %d\n',length(allPeakIdx))
    %save(strcat(outdir,'/',outname,'assigned.mat'),'groupings','peakIdxGroup',...
        %'likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
    save(fullfile(outdir,strcat(outname,'dT',num2str(diffThreshold),...
        'sT',num2str(sigmaThreshold),'nL',num2str(noiseLevel),'assigned.mat')),'groupings','peakIdxGroup',...
    'likes','allPeakIdx','allNormalizedPeaks');
    %makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
    makePeakPlot(dfilt, peakIdxGroup, 1:length(outputData.templates));
    savefig(fullfile(outdir,strcat(outname,newtempoutname,'dT',num2str(diffThreshold),...
        'sT',num2str(sigmaThreshold),'nL',num2str(noiseLevel),'AllColored.fig')));
end