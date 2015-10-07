function PlotTemplatesOneFile(filename,initdir)
    %Runs makePeakPlot for a file in the TrainingSet or ValidationSet
    %Input:
    %filename -> filename prefix without .wav (e.g.,
    %'Channel1_070714_nasuta_0.014-0.13')
    %initdir -> subdirectory location of the file (e.g., 'TrainingSet')
    %initdir = 'J:/SoundData/PureSpeciesForClustering/TrainingSet'; %modify to allow manual specification
    dirpref = 'J:/SoundData/PureSpeciesForClustering'
    outdir = 'J:/SoundData/PureSpeciesForClustering/AnalyzerOutput';
    fsadir = 'J:/fly_song_analyzer_032412/fly_song_analyzer_032412'
    outname = 'ValidationSet1';
    tempoutname = 'Templates';
    %Load previously generated files.
    onesong = load(strcat(dirpref,'/',initdir,'/',filename,'.wav_out','/PS_',filename,'.mat'));
    alltemps = load(strcat(outdir,'/',outname,tempoutname,'.mat'));
    %Create 'options' structure.
    wmoptions = struct('fs',6000);
    %Change to the fly_song_analyzer directory.
    cd(fsadir);
    %Assign data from this song to templates.
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(onesong.Data.d,alltemps.templates,wmoptions);
    %Plot the output.
    makePeakPlot(onesong.Data.d,peakIdxGroup,[1 2 3 4 5 6 7 8 9 10 11 12])
    %Return to the original directory.
    cd 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/'