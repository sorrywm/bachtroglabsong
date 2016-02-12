function GetNoisePeaks(wav_file, prevtempfile, whichsignal, segopts)
    %Load options. Having another function to load them does not work.
    %wmoptions = LoadOptions(segopts);
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
    addpath(segmenterdir,plotanalyzerdir,butterdir,chronuxdir);
    if exist('song_range','var')==0
        song_range = [];
        outname = strcat(wav_file,'_data');
    else
        outname = strcat(wav_file,num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
    end
    [~,wavbase,ext] = fileparts(wav_file);
    splittempname = strsplit(prevtempfile,'/');
    newtempoutname = splittempname{length(splittempname)};

    %Read and filter wavfile.
    [~,dfilt] = ReadAndFilterWavFile(outname, wav_file, song_range, filtcut, fs, 'TRUE');

    %Load in previously computed templates.
    fprintf('Loading previous templates: %s.\n', prevtempfile);
    load(prevtempfile);
    if length(whichsignal) > length(newtemplates)
        fprintf('Keeping all signals: %s.\n', num2str(length(newtemplates)));
        try
            whichsignal = whichsignal{1:length(newtemplates)};
        catch MEtemp
            disp(whichsignal)
            disp(length(newtemplates))
            disp(class(whichsignal))
            rethrow(MEtemp)
        end
    end

    %Assign data to templates.
    fprintf('Assigning %s to templates from %s.\n', wavbase, newtempoutname);
    try
        [~,peakIdxGroup,~,~,~,~,~] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
    catch MEadtt
        display(path)
        rethrow(MEadtt)
    end

    %Get peakIdx for all signal peaks.
    signalPeakIdx = {};
    for i = 1:length(whichsignal)
        if isa(signalPeakIdx,'cell')
            signalPeakIdx = cell2mat(signalPeakIdx);
        end
        signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{whichsignal(i)});
    end
    signalPeakIdx = sort(signalPeakIdx);

    %Save only signal peaks
    dataoutname = strcat(outname,'signal',sprintf('%d',whichsignal), ...
        'signalpeaks.mat');
    save(dataoutname,'signalPeakIdx')
end
