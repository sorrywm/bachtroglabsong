function CreateSpeciesTemplatesFiltOldFSCS(initdir, wavbase, segopts, diffThreshold)
    %Set defaults for the following:
    %plotanalyzerdir = '/Users/wynnmeyer/repos/OldFlySongClusterSegment/';
    segmenterdir = '/Users/wynnmeyer/repos/OldFlySongClusterSegment/';
    butterdir='/Users/wynnmeyer/repos/bachtroglabsong';
    filtcut=200;
    fs = 6000; %read from file?
    %wmoptions =
    %struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
    tpd = min(diffThreshold*2-1,50);
    %wmoptions = struct('fs',6000,'diffThreshold',diffThreshold,'template_pca_dimension',10);
    wmoptions = struct('fs',6000,'diffThreshold',diffThreshold,...
        'template_pca_dimension',tpd,'use_likelihood_threshold',1,...
        'baseline_threshold',-90);
    relvars = {'fs','diffThreshold','template_pca_dimension'};
    %Replace the defaults if desired:
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:});
    else
        fprintf('The options file %s does not exist. Using default options.\n',segopts)
    end
    
    %addpath(segmenterdir,plotanalyzerdir,butterdir);
    addpath(genpath(segmenterdir),butterdir);
    wav_file = strcat(initdir,'/',wavbase); %read this in?
    song_range = [];
    outdir = initdir;
    outname = strcat(wavbase,'_data');
    newtempoutname = strcat('TemplatesFrom',wavbase,'Filt');

    %Generate a data file from the .wav file
    %Read in origfs from this file (convert to fs if not equal) 
    %To do: Only run if _data file does not exist
    %From FlySongSegmenterWAV:
    fprintf('Grabbing song from wav file %s.\n', wav_file);
    if ~isempty(song_range)
        [origsong, origfs] = audioread(wav_file,song_range);
    else
        [origsong, origfs] = audioread(wav_file);
    end
    %Save this file?
    if origfs ~= fs
        %subsample origsong to equalize the sampling frequency
        fprintf(['Sub-sampling %s (initial sampling frequency %d Hz) to ' ...
                 'match desired sampling frequency (%d Hz)\n'], ...
                 wav_file,origfs,fs);
        [P,Q] = rat(fs/origfs);
        song = resample(origsong,P,Q);
    else
        song = origsong;
    end
    d=song;
    dfilt = tybutter(d,filtcut,fs,'high');
    save(strcat(outdir,'/',outname,'.mat'),'d', 'dfilt');

    %Reduced PCA dimension (default 50) because of following error:
    %Index exceeds matrix dimensions.
    %Error in createTemplates (line 70)
    %    scores = scores(:,1:options.template_pca_dimension);

    %To do: Create a new folder for all these output files
    %To do: Shut down parallel pool after completion
    
    [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = ...
        createTemplates(dfilt, wmoptions);
    %[outputData,allPeakIdx,allNormalizedPeaks,peakAmplitudes,isNoise,scores,options] = ...
                                %createTemplates(dfilt,wmoptions);
    savefig(strcat(outdir,'/',outname,newtempoutname,'TemplateHistograms.fig'));
    close;
    sprintf('All peaks found (old code): %d\n',length(allPeakIdx))
    %save(strcat(outdir,'/',outname,newtempoutname,'dT',diffThreshold,'.mat'),'newtemplates');
    save(strcat(outdir,'/',outname,newtempoutname,'dT',diffThreshold,'.mat'),'outputData');
    save(strcat(outdir,'/',outname,'outputfromcreateTemplates.mat'),'allPeakIdx',...
        'allNormalizedPeaks','peakAmplitudes','isNoise','scores','options');
    %[groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks] = ...
                     assignDataToTemplates(dfilt,outputData,options);
    %save(strcat(outdir,'/',outname,'assigned.mat'),'groupings','peakIdxGroup',...
        %'likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
    save(strcat(outdir,'/',outname,'assigned.mat'),'groupings','peakIdxGroup',...
    'likes','allPeakIdx','allNormalizedPeaks');
    %makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
    makePeakPlot(dfilt, peakIdxGroup, 1:length(outputData.templates));
    savefig(strcat(outdir,'/',outname,newtempoutname,'dT',diffThreshold,'AllColored.fig'));
end