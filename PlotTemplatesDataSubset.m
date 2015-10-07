function(filename,initdir)
    %Runs makePeakPlot for a file in the TrainingSet or ValidationSet
    %Input:
    %filename -> filename prefix without .wav (e.g.,
    %'Channel1_070714_nasuta_0.014-0.13')
    %initdir -> subdirectory location of the file (e.g., 'TrainingSet')
    %initdir = 'J:/SoundData/PureSpeciesForClustering/TrainingSet'; %modify to allow manual specification
    outdir = 'J:/SoundData/PureSpeciesForClustering/AnalyzerOutput';
    fsadir = 'J:/fly_song_analyzer_032412/fly_song_analyzer_032412'
    %outname = 'ValidationSet1';
    %tempoutname = 'Templates';
    %Load previously generated files.
    allsongs = load(strcat(outdir,'/',outname,'.mat'));
    alltemps = load(strcat(outdir,'/',outname,tempoutname,'.mat'));
    %Create 'options' structure.
    wmoptions = struct('fs',6000);
    %Change to the fly_song_analyzer directory.
    cd(fsadir);
    %Subset the data. Example: ssulf (1-5)
    %whichfiles = [1 2 3 4 5];
    newlengths = vertcat(0,allsongs.l);
%Make a (1-D array?) containing the start and stop points for all these
%songs.
subset = [];
for f = 1:length(whichfiles)
    %if length(subset) > 0
        %Here's where I transpose the array to a 1-column array.
        %subset = subset';
    %end
    %This is the part that throws an error.
    %But whenever I do size(subset) and size(newlengths), they both just
    %have one column.
    subset=horzcat(subset,(newlengths(whichfiles(f))+1):newlengths(whichfiles(f)+1));
end
subset=subset';
%Assign this subset to templates.
[groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(allsongs.d(subset),alltemps.templates,wmoptions);
%Plot the output.
makePeakPlot(allsongs.d(subset),peakIdxGroup,[1 2 3 4 5 6 7 8 9 10 11 12])
cd 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/'