function CreateSpeciesTemplates(initdir, wavbase, isshort)
if nargin < 1 || isempty(initdir)
    initdir = 'J:/SoundData/PerSpeciesRecordingsMono/ssulf'; %location of wavfile
end
if nargin < 2 || isempty(wavbase)
    wavbase = 'Channel1_122214_ssulf.wav';
end
if nargin < 3 || isempty(isshort)
    isshort = 'n';
end
wav_file = strcat(initdir,'/',wavbase); %read this in?
song_range = [];
outdir = initdir;
outname = strcat(wavbase,'_data');
newtempoutname = strcat('TemplatesFrom',wavbase);
%analyzerdir = 'J:/fly_song_analyzer_032412/fly_song_analyzer_032412/'
analyzerdir = 'C:/Users/Dungeon/Documents/MATLAB/FlySongClusterSegment/FlySongClusterSegment/'
segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/'

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

%Create 'options' structure.
wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
shortoptions = struct('fs',6000,'diffThreshold',3,'template_pca_dimension',5);
%Reduced PCA dimension (default 50) because of following error:
%Index exceeds matrix dimensions.
%Error in createTemplates (line 70)
%    scores = scores(:,1:options.template_pca_dimension);

%Set directory to location of fly_song_analyzer.
cd(analyzerdir);

%Try instead generating new templates based just on this file.
if isshort == 'y'
    fprintf('Using short IPI options.\n');
    [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(song, shortoptions);
    savefig(strcat(outdir,'/',outname,newtempoutname,'ShortTemplateHistograms.fig'));
    save(strcat(outdir,'/',outname,newtempoutname,'Short.mat'),'newtemplates');
else
    [newtemplates,allPeakIdx,allNormalizedPeaks,isNoise,scores,options] = createTemplates(song, wmoptions);
    savefig(strcat(outdir,'/',outname,newtempoutname,'TemplateHistograms.fig'));
    save(strcat(outdir,'/',outname,newtempoutname,'.mat'),'newtemplates');
end
    cd(segmenterdir);