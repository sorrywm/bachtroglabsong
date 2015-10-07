function FilterOnly(initdir, wavbase, song_range, filtcut)
%e.g.:
%FilterAndPlot('J:/SoundData/Athabasca','Channel1_050315_x13F1.wav',[],200)

%Modify the following line to the location of tybutter.m
butterdir='C:/Users/Dungeon/Downloads';
addpath(butterdir);

if nargin < 4 || isempty(filtcut)
    filtcut = 100;
end
%segmenterdir = 'C:/Users/Dungeon/Documents/GitHub/Flysong/FlySongSegmenter/';
%Read in a single channel .wav file.
wav_file = strcat(initdir,'/',wavbase);
%out_file = strcat(initdir,'/',wavbase,'_filt',num2str(filtcut),'.wav');
out_file = strcat(initdir,'/',wavbase,'_filt',num2str(filtcut),'.wav');
if exist(out_file,'file') ~= 2
    %Only write if file doesn't already exist.
    fprintf('Grabbing song from wav file %s.\n', wav_file);
    if ~isempty(song_range)
        [song,fs] = audioread(wav_file,song_range);
        outname=strcat(wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_data');
        out_file = strcat(initdir,'/',wavbase,'_',num2str(song_range(1)),'-',num2str(song_range(2)),'_filt',num2str(filtcut),'.wav');
    else
        [song,fs] = audioread(wav_file);
        outname=strcat(wavbase,'_data');
        out_file = strcat(initdir,'/',wavbase,'_filt',num2str(filtcut),'.wav');
    end
    %Save this file. 
    %Possibly modify code to check for file's existence.
    d=song;
    outdir=initdir;
    %outname=strcat(wavbase,'_data');
    %outname=strcat(wavbase,'_',num2str(song_range(1)),'-',num2str(songrange(2)),'_data');
    save(strcat(outdir,'/',outname,'.mat'),'d');
    %Run a high-pass filter on the data.
    %cd(butterdir);
    dfilt = tybutter(d,filtcut,fs,'high');
    audiowrite(out_file,dfilt,fs);
    %cd(segmenterdir);
end
