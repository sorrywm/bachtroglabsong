%This can't load the options if run in another file. It will only load them locally.
function wmoptions = LoadOptions(segopts)
    relvars = {'fs','diffThreshold','template_pca_dimension'};
    if exist(segopts,'file') == 2
        load(segopts); %This is a structure with the following variables saved:
        %analyzerdir, plotanalyzerdir, segmenterdir, butterdir (paths),
        %fs, diffThreshold, template_pca_dimension (FlySongSegmenter options),
        %isshort, filtcut (filtering and clustering options)
        wmoptions = load(segopts,relvars{:});
    else
        %Modify the following to the location of your versions of these programs.
        %Alternatively, save these locations and load as segopts.
        analyzerdir = '../FlySongClusterSegment/';
        plotanalyzerdir = '../fly_song_analyzer_032412/';
        segmenterdir = '../FlySongSegmenter/';
        chronuxdir = '../FlySongSegmenter/chronux/';
        butterdir = pwd;
        fs = 6000; %read from file?
        diffThreshold = 20;
        template_pca_dimension = 10;
        wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
        filtcut=200;
        isshort='n';
        domalefemale='FALSE';
    end
end
