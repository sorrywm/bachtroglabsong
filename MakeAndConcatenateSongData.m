%For a list of songs, generate data files using FlySongSegmenterWAVmod, and
%then load and concatenate the data files, saving the output for use in
%CreateTemplates.
%If a previous concatenated data object exists, remove it.
if exist('datacat')==1
    clear datacat
end
%Navigate to J:/SoundData/PureSpeciesForClustering/TrainingSet or
%J:/SoundData/PureSpeciesForClustering/ValidationSet
%initdir = varargin(1)
initdir = 'J:/SoundData/PureSpeciesForClustering/ValidationSet'; %modify to allow manual specification
outdir = 'J:/SoundData/PureSpeciesForClustering/AnalyzerOutput';
outname = 'ValidationSet1';
cd(initdir);
%List all .wav files
files = ls('*.wav');
%Then navigate to the folder with FlySongSegmenter
cd('C:/Users/Dungeon/Documents/GitHub/FlySong/FlySongSegmenter');
%Create a blank data structure
%The name within the structure must be 'd' (otherwise modified
%createTemplates, etc., will not read it in properly).
d=[];
l=[];
%Generate a data file, load the resulting data, and append the blank data
%structure
%Can one convert wav -> "data" without FlySongSegmenter?
%for f = size(files,1)
for f = 1:size(files,1)
    FlySongSegmenterWAVmod(strcat(initdir,'/',files(f,:)),[],'./paramsAnne_mod.m');
    repmat = strrep(files(f,:),'.wav','.mat');%replace .wav with .mat in the filename
    NewData=load(strcat(initdir,'/',files(f,:),'_out/PS_',repmat));
    d=vertcat(d,NewData.Data.d);
    l=vertcat(l,length(d));
end
%Save concatenated file to AnalyzerOutput.
save(strcat(outdir,'/',outname,'.mat'),'d','l','files');