function FilterAndPlot(initdir, wavbase, song_range, fs)
segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/';
%Read in a single channel .wav file.
wav_file = strcat(initdir,'/',wavbase);
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range)
    song = audioread(wav_file,song_range);
else
    song = audioread(wav_file);
end
%Save this file. 
%Possibly modify code to check for file's existence.
d=song;
outdir=initdir;
outname=strcat(wavbase,'_data');
save(strcat(outdir,'/',outname,'.mat'),'d');
%Run a high-pass filter on the data.
%butterdir='C:/Users/Dungeon/Downloads';
%cd(butterdir);
%dfilt = tybutter(d,100,fs,'high');
%Plot the output in a human-readable scale
%(i.e., x-axis in s or ms).
plot(d/fs,'b-');
cd(segmenterdir);

