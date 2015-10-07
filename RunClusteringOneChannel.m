function RunClusteringOneChannel(initdir, wavbase, nosignal, isshort)
if nargin < 1 || isempty(initdir)
    initdir = 'J:/SoundData/PerSpeciesRecordingsMono/ssulf'; %location of wavfile
end
if nargin < 2 || isempty(wavbase)
    wavbase = 'Channel1_122214_ssulf.wav';
end
if nargin < 3 || isempty(nosignal)
    nosignal = 7
end
if nargin < 4 || isempty(isshort)
    isshort = 'n';
end
wav_file = strcat(initdir,'/',wavbase); %read this in?
song_range = [];
outdir = initdir;
segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/';
outname = strcat(wavbase,'_data');
newtempoutname = strcat('TemplatesFrom',wavbase);
prevtempfile = strcat(outdir,'/',outname,newtempoutname,'.mat');
maxIPI = 0.2; %maximum IPI before a new bout is formed (in s)

analyzerdir = 'J:/fly_song_analyzer_032412/fly_song_analyzer_032412/'
%analyzerdir = 'C:/Users/Dungeon/Documents/MATLAB/FlySongClusterSegment/FlySongClusterSegment/'

%Generate a data file from the .wav file
%Can one convert wav -> "data" without FlySongSegmenter?
%Yes! From FlySongSegmenterWAV:
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range)
    song = audioread(wav_file,song_range);
else
    song = audioread(wav_file);
end

%Save this file?
d=song;
save(strcat(outdir,'/',outname,'.mat'),'d');
%Load in previously computed templates.
load(prevtempfile);
%Create 'options' structure.
wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
shortoptions = struct('fs',6000,'diffThreshold',3,'template_pca_dimension',5);
%Reduced PCA dimension (default 50) because of following error:
%Index exceeds matrix dimensions.
%Error in createTemplates (line 70)
%    scores = scores(:,1:options.template_pca_dimension);

%Set directory to location of fly_song_analyzer.
cd(analyzerdir);

%Assign data to templates.
%Time this.
if isshort == 'y'
    tic;
    fprintf('Using short IPI options.\n');
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(song,newtemplates,shortoptions);
    toc;
else
    tic;
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(song,newtemplates,wmoptions);
    toc;
end

%Plot all templates (if signal templates difficult to define)
if isshort == 'y'
    makePeakPlot(song, peakIdxGroup, [1 2 3 4 5 6 7 8]);
    savefig(strcat(outdir,'/',outname,newtempoutname,'ShortAllColored.fig'));
else
    makePeakPlot(song, peakIdxGroup, [1 2 3 4 5 6 7 8 9 10 11 12]);
    savefig(strcat(outdir,'/',outname,newtempoutname,'AllColored.fig'));
end

%Compute and plot IPI.
%Use all peaks, rather than template 1?
%Goal: use just peaks from signal templates
%If just using one template:
%w = diff(peakIdxGroup{1})./options.fs;
%1) How can we select just signal templates?
%2) How can we use peakIdxGroup for multiple templates?
%signaltemplates = [1 2 3 4 5 6 7];
signalPeakIdx = {};
for i = 1:nosignal
    if isa(signalPeakIdx,'cell')
        signalPeakIdx = cell2mat(signalPeakIdx);
    end
    signalPeakIdx = horzcat(signalPeakIdx,peakIdxGroup{i});
end
signalPeakIdx = sort(signalPeakIdx);
%w = diff(allPeakIdx)./wmoptions.fs;
w = diff(signalPeakIdx)./wmoptions.fs;
w = w(w <= maxIPI);
[Y,X] = hist(w,500); %switch to 'histogram' in more recent releases of MATLAB
Y = Y  ./ (sum(Y)*(X(2)-X(1)));
plot(X(1:100)*1000,Y(1:100))
title(strcat('IPI histogram for ',wavbase))
xlabel('Inter-pulse interval (IPI)')
ylabel ('Count')
if isshort == 'y'
    savefig(strcat(outdir,'/',outname,newtempoutname,'SignalTemplatesIPIHistShort.fig'));
else
    savefig(strcat(outdir,'/',outname,newtempoutname,'SignalTemplatesIPIHist.fig'));
end
sortY = fliplr(sort(Y)); %order the counts from most to least
for i=1:10
    X(find(Y==sortY(i)))*1000 %print the top 10 X values.... should contain the mode
end
cd(segmenterdir);

