function CreateSpeciesTemplatesFilt(initdir, wavbase, isshort, fs, filtcut)
%Modify the following to the location of your versions of these programs.
analyzerdir = 'D:/BackupFromDesktop072815/MATLABCode/MATLAB/FlySongClusterSegment/FlySongClusterSegment/';
plotanalyzerdir = 'D:/BackupFromDesktop072815/MATLABCode/fly_song_analyzer_032412/fly_song_analyzer_032412/';
butterdir='D:/BackupFromDesktop072815/MATLABCode';
load wmoptions;

currentFolder = pwd;

if nargin < 5 || isempty(filtcut)
    filtcut = 100;
    if nargin < 4 || isempty(fs)
        fs = 6000;
        if nargin < 3 || isempty(isshort)
            isshort = 'n';
            if nargin < 2 || isempty(wavbase)
                wavbase = 'Channel1_122214_ssulf.wav';
                if nargin < 1 || isempty(initdir)
                    initdir = 'J:/SoundData/PerSpeciesRecordingsMono/ssulf'; %location of wavfile
                end
            end
        end
    end
end
wav_file = strcat(initdir,'/',wavbase); %read this in?
song_range = [];
outdir = initdir;
outname = strcat(wavbase,'_data');
newtempoutname = strcat('TemplatesFrom',wavbase,'Filt');

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
cd(butterdir);
dfilt = tybutter(d,filtcut,fs,'high');
save(strcat(outdir,'/',outname,'.mat'),'d', 'dfilt');

%Create 'options' structure.
%wmoptions = struct('fs',6000,'diffThreshold',20,'template_pca_dimension',10);
shortoptions = struct('fs',6000,'diffThreshold',3,'template_pca_dimension',5);
wmoptions10 = struct('fs',6000,'diffThreshold',10,'template_pca_dimension',10);
wmoptions30 = struct('fs',6000,'diffThreshold',30,'template_pca_dimension',10);
%Reduced PCA dimension (default 50) because of following error:
%Index exceeds matrix dimensions.
%Error in createTemplates (line 70)
%    scores = scores(:,1:options.template_pca_dimension);

%Set directory to location of fly_song_analyzer.
cd(analyzerdir);

%Try instead generating new templates based just on this file.
%Also plot all templates in this script.
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
    save(strcat(outdir,'/',outname,newtempoutname,'.mat'),'newtemplates');
    cd(plotanalyzerdir);
    [groupings,peakIdxGroup,likes,allPeakIdx,allNormalizedPeaks,coeffs,projStds] = assignDataToTemplates(dfilt,newtemplates,wmoptions);
    save(strcat(outdir,'/',outname,'assigned.mat'),'groupings','peakIdxGroup','likes','allPeakIdx','allNormalizedPeaks','coeffs','projStds');
    makePeakPlot(dfilt, peakIdxGroup, [1:length(newtemplates)]);
    savefig(strcat(outdir,'/',outname,newtempoutname,'AllColored.fig'));
end
    cd(currentFolder);