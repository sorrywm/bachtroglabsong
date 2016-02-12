function CreateSpeciesTemplatesFiltLoadOpts(initdir, wavbase, segopts)
    %Set defaults for the following:
    analyzerdir = '/Users/wynnmeyer/repos/FlySongClusterSegment/';
    plotanalyzerdir = '/Users/wynnmeyer/repos/fly_song_analyzer_032412/';
    segmenterdir = '/Users/wynnmeyer/repos/FlySongClusterSegment/';
    butterdir='/Users/wynnmeyer/repos/bachtroglabsong';
    isshort='n';
    fs=6000;
    filtcut=200;
    fs = 6000; %read from file?
    diffThreshold = 20;
    template_pca_dimension = 10;
    wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);

    relvars = {'fs','diffThreshold','template_pca_dimension'};
    %Replace the defaults if desired:
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:})
    else
        fprintf('The options file %s does not exist. Using default options.\n',segopts)
    end
    
    addpath(segmenterdir,plotanalyzerdir,butterdir);
    currentFolder = pwd;
    wav_file = strcat(initdir,'/',wavbase); %read this in?
    song_range = [];
    outdir = initdir;
    outname = strcat(wavbase,'_data');
    newtempoutname = strcat('TemplatesFrom',wavbase,'Filt');

    %Generate a data file from the .wav file
    %To do: Only run if _data file does not exist
    %From FlySongSegmenterWAV:
    fprintf('Grabbing song from wav file %s.\n', wav_file);
    if ~isempty(song_range)
        song = audioread(wav_file,song_range);
    else
        song = audioread(wav_file);
    end
    %Save this file?
    d=song;
    %cd(butterdir);
    dfilt = tybutter(d,filtcut,fs,'high');
    save(strcat(outdir,'/',outname,'.mat'),'d', 'dfilt');

    %Possible 'options' structures.
    %wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
    %shortoptions = struct('fs',6000,'diffThreshold',3,'template_pca_dimension',5);
    %wmoptions10 = struct('fs',6000,'diffThreshold',10,'template_pca_dimension',10);
    %wmoptions30 = struct('fs',6000,'diffThreshold',30,'template_pca_dimension',10);

    %Reduced PCA dimension (default 50) because of following error:
    %Index exceeds matrix dimensions.
    %Error in createTemplates (line 70)
    %    scores = scores(:,1:options.template_pca_dimension);

    %Set directory to location of fly_song_analyzer.
    cd(analyzerdir);

    %Try instead generating new templates based just on this file.
    %Also plot all templates in this script.
    %To do: Create a new folder for all these output files
    %To do: Shut down parallel pool after completion
    if strcmp(isshort,'y')
        fprintf('Using short IPI options.\n');
        [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(dfilt, shortoptions);
        savefig(strcat(outdir,'/',outname,newtempoutname,'ShortTemplateHistograms.fig'));
        close;
        save(strcat(outdir,'/',outname,newtempoutname,'Short.mat'),'newtemplates');
        cd(plotanalyzerdir);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,shortoptions);
        save(strcat(outdir,'/',outname,'Shortassigned.mat'),'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outdir,'/',outname,newtempoutname,'ShortAllColored.fig'));
    elseif strcmp(isshort,'ten')
        fprintf('Using diffThreshold 10.\n');
        [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(dfilt, wmoptions10);
        savefig(strcat(outdir,'/',outname,newtempoutname,'dT10TemplateHistograms.fig'));
        close;
        save(strcat(outdir,'/',outname,newtempoutname,'dT10.mat'),'newtemplates');
        cd(plotanalyzerdir);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions10);
        save(strcat(outdir,'/',outname,'dT10assigned.mat'),'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outdir,'/',outname,newtempoutname,'dT10AllColored.fig'));
    elseif strcmp(isshort,'thirty')
        fprintf('Using diffThreshold 30.\n');
        [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(dfilt, wmoptions30);
        savefig(strcat(outdir,'/',outname,newtempoutname,'dT30TemplateHistograms.fig'));
        close;
        save(strcat(outdir,'/',outname,newtempoutname,'dT30.mat'),'newtemplates');
        cd(plotanalyzerdir);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions30);
        save(strcat(outdir,'/',outname,'dT30assigned.mat'),'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outdir,'/',outname,newtempoutname,'dT30AllColored.fig'));
    else
        [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(dfilt, wmoptions);
        savefig(strcat(outdir,'/',outname,newtempoutname,'TemplateHistograms.fig'));
        close;
        save(strcat(outdir,'/',outname,newtempoutname,'dT',diffThreshold,'.mat'),'newtemplates');
        cd(plotanalyzerdir);
        [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
        save(strcat(outdir,'/',outname,'assigned.mat'),'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
        makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
        savefig(strcat(outdir,'/',outname,newtempoutname,'dT',diffThreshold,'AllColored.fig'));
    end
end