function BandpassFilter(initdir, wavbase, song_range, filtcut)
if nargin < 4 || isempty(filtcut)
    filtcut = [250 350];
end
filtcut
%segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/';
%Read in a single channel .wav file.
wav_file = strcat(initdir,'/',wavbase);
%out_file = strcat(initdir,'/',wavbase,'_filt',num2str(filtcut),'.wav');
if ischar(filtcut)
    filtcut = str2num(filtcut);
end
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range) && strcmp(song_range,'[]') == 0
    [song,fs] = audioread(wav_file,song_range);
    outname=strcat(wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
    out_file = strcat(initdir,'/',wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_bpfilt',num2str(filtcut),'.wav');
    out_file = strrep(out_file, ' ', '_');
else
    [song,fs] = audioread(wav_file);
    outname=strcat(wavbase,'_data');
    out_file = strcat(initdir,'/',wavbase,'_bpfilt',num2str(filtcut),'.wav');
    out_file = strrep(out_file, ' ', '_');
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
%addpath 'C:/Users/Dungeon/Downloads';
try
    dfilt = tybutter(d,filtcut,fs,'bandpass');
catch ME
    fprintf('Issue with filtcut: %s, class: %s, length: %s.\n',num2str(filtcut),class(filtcut),num2str(length(filtcut)))
    rethrow(ME)
end
%Plot the output in a human-readable scale
%(i.e., x-axis in s or ms).
plot((1:length(dfilt))/fs,dfilt,'b-');
savefig(strcat(outdir,'/',outname,'BPFiltered',num2str(filtcut),'.fig'));
close; 
audiowrite(out_file,dfilt,fs);
%cd(segmenterdir);
