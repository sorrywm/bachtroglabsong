initdir = 'J:/SoundData/PureSpeciesForClustering/TrainingSet'; %modify to allow manual specification
outdir = 'J:/SoundData/PureSpeciesForClustering/AnalyzerOutput';
outdir2 = 'J:/SoundData/PureSpeciesForClustering/ValidationSet';
fsadir = 'J:/fly_song_analyzer_032412/fly_song_analyzer_032412'
outname = 'ValidationSet1';
tempoutname = 'Templates';
%Load previously generated file.
allsongs = load(strcat(outdir,'/',outname,'.mat'));
%Create 'options' structure.
wmoptions = struct('fs',6000);
%Change to the fly_song_analyzer directory.
cd(fsadir);
%Create templates and save to file.
[templates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(allsongs, wmoptions);
save(strcat(outdir,'/',outname,tempoutname,'.mat'),'templates');
%Assign data to templates.
[groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(allsongs,templates,wmoptions);
%Plot the "signal" templates (in this case 2 - 5)
makePeakPlot(allsongs.d, peakIdxGroup, [2 3 4 5])
savefig(strcat(outdir2,'/',outname,tempoutname,'Colored.mat'))
%Close out the GUI. Is this possible within this code?
%Plot templates 3 at a time.
%makePeakPlot(allsongs,peakIdxGroup,[1 2 3]);
%makePeakPlot(allsongs,peakIdxGroup,[4 5 6]);
%makePeakPlot(allsongs,peakIdxGroup,[7 8 9]);
%makePeakPlot(allsongs,peakIdxGroup,[10 11 12]);