%Required for running wavNaming.
%Attempt to write code to split a multi-channel .wav file.
%Input: .wav filename, channel to extract, output filename
%Currently saves .wav file after 100 Hz filter is applied.
%What is the most up-to-date version of this?
%E.g.:
%ExtractSingleChannelsFromWAV('J:/SoundData/Recordings07302014/20140730T103939a.wav',5,'J:/SoundData/PerSpeciesRecordingsMono/albomicans/Channel5_073014_albomicans.wav_data')
%function ExtractSingleChannelsFromWAV(wavfile,whichchannel,outname,fs)
function errchan = ExtractSingleChannelsFromWAV_matt(wavfile,whichchannel,outname)
    %Modify the following to the directory where you saved tybutter.m
    %butterdir='D:\BackupFromDesktop072815\MATLABCode';  %changed!
    butterdir='/Users/wynnmeyer/repos/bachtroglabsong';
    
    addpath(butterdir)
    %Extract one channel from a wavfile, apply filter, and save the data.
    if nargin < 1 || isempty(wavfile)
       wavfile='J:\SoundData\Recordings07292014\20140729T120920a.wav';
    end
    %Save if there is an issue with the number of channels
    errchan = 0;
    %Getting number of channels:
    info=audioinfo(wavfile);
    if whichchannel > info.NumChannels
        errchan = 1;
    end
    %Because files are large, data will need to be parsed a few bits at a time.
    %e.g.: http://www.mathworks.com/matlabcentral/newsreader/view_thread/302506
    % construct the object, set the filename equal to your .wav file
    % set the SamplesPerFrame property to your desired value
    h = dsp.AudioFileReader('Filename',wavfile,'SamplesPerFrame',10000); 
    % add a for loop to repeat the following for each channel (what is kept in
    % memory?)
    % just initialize a vector of zeros to carry the first empty frame--we'll get rid of this
    audiodata = zeros(h.SamplesPerFrame,1);
    %Try to troubleshoot so it doesn't require too much memory.
    %initialize a vector of zeros for the whole file
    %audiodata = zeros(info.TotalSamples);
    %wind = 1:h.SamplesPerFrame;
    % start the while loop to read in the two-channel audio frame by frame
    %tic;
    if errchan == 0
        while ~isDone(h)
            try
                % read the audio frame (1024 samples)
                audio = step(h);
                % just keep one channel
                audiodata = [audiodata; audio(:,whichchannel)];
                %audiodata(wind) = audio(:,whichchannel);
                %wind = wind + h.SamplesPerFrame;
            catch ME
                if (strcmp(ME.identifier,'dspshared:system:libOutFromMmFile'))
                    %"the audio input stream has become unresponsive"
                    errchan = 2;
                    %error('Issue with input stream for channel %s\n',whichchannel)
                    continue
                else
                    wavfile
                    ME.identifier
                    rethrow(ME)
                end            
            end
        end
    end
    if errchan == 0
        % get rid of the zeros at the beginning
        audiodata(1:h.SamplesPerFrame) = [];
        d = audiodata;
        dfilt = tybutter(d,100,h.SampleRate,'high'); %attempt to read fs rather than supply it
        dfilt200 = tybutter(d,200,h.SampleRate,'high'); %also do 200 Hz high-pass
        %save(strcat(outname,'.mat'),'d','dfilt','dfilt200');
        audiowrite(strcat(outname,'.wav'),dfilt,6000);
    end
end
