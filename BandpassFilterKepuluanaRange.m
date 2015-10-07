function BandpassFilterKepuluanaRange(initdir, wavbase, song_range, fs, filtcut)
if nargin < 5 || isempty(filtcut)
    filtcut = [250 350];
end
segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/';
%Read in a single channel .wav file.
wav_file = strcat(initdir,'/',wavbase);
%out_file = strcat(initdir,'/',wavbase,'_filt',num2str(filtcut),'.wav');
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range)
    song = audioread(wav_file,song_range);
    outname=strcat(wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
    out_file = strcat(initdir,'/',wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_bpfilt',num2str(filtcut),'.wav');
else
    song = audioread(wav_file);
    outname=strcat(wavbase,'_data');
    out_file = strcat(initdir,'/',wavbase,'_bpfilt',num2str(filtcut),'.wav');
end
%Save this file. 
%Possibly modify code to check for file's existence.
d=song;
outdir=initdir;
%outname=strcat(wavbase,'_data');
%outname=strcat(wavbase,'_',num2str(song_range(1)),'-',num2str(songrange(2)),'_data');
save(strcat(outdir,'/',outname,'.mat'),'d');
%Run a high-pass filter on the data.
%butterdir='C:/Users/Dungeon/Downloads';
%cd(butterdir);
addpath 'C:/Users/Dungeon/Downloads';
dfilt = tybutter(d,filtcut,fs,'bandpass');
%Plot the output in a human-readable scale
%(i.e., x-axis in s or ms).
plot((1:length(dfilt))/fs,dfilt,'b-');
savefig(strcat(outdir,'/',outname,'BPFiltered',num2str(filtcut),'.fig'));
close; 
audiowrite(out_file,dfilt,fs);
cd(segmenterdir);