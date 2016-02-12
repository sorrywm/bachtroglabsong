%Extract one channel from a .wav file.
%Input: .wav filename, channel to extract, output filename, options file (for directories)
%Currently saves unfiltered .wav file.... perhaps save data instead?
function errchan = ExtractSingleChannel(wavfile,whichchannel,outname)
    %Extract one channel from a wavfile, and save the data.
    if nargin < 3
       error('Must specify wav file, channel, and output name.')
    end

    if isstr(whichchannel)
        whichchannel = str2num(whichchannel);
    end
    try
        info=audioinfo(wavfile);
        if whichchannel > info.NumChannels
            error('There are only %s channels in %s, not %s.\n',...
                  num2str(info.NumChannels),wavfile,num2str(whichchannel))
        end
    catch MEinfo
        fprintf('%s does not exist.\n',wavfile);
        exit(1)
    end

    %Because files are large, data will need to be parsed a few bits at a time.
    %e.g.: http://www.mathworks.com/matlabcentral/newsreader/view_thread/302506
    % construct the object, set the filename equal to your .wav file
    % set the SamplesPerFrame property to your desired value
    %h = dsp.AudioFileReader('Filename',wavfile,'SamplesPerFrame',10000); 
    % just initialize a vector of zeros to carry the first empty frame--we'll get rid of this
    %audiodata = zeros(h.SamplesPerFrame,1);
        
    % construct the object, set the filename equal to your .wav file
    % set the SamplesPerFrame property to your desired value
    % NOTE: Reading 1MB at a time loads the entire 2-3 GB file in about 1 minute!
    %SPF = 1000000;
    SPF = 1048576;
    h = dsp.AudioFileReader('Filename', wavfile, 'SamplesPerFrame', SPF);
    %Need to incorporate eof.
    totalSteps = (info.TotalSamples - mod(info.TotalSamples, SPF)) / SPF;
    %The following doesn't make sense with the check of stepNum against totalSteps.
    %if mod(info.TotalSamples, SPF) > 0
    %    totalSteps = totalSteps + 1;
    %end
    % New: Read number of channels from .wav file (info.NumChannels).
    %audiodata = zeros(info.TotalSamples, NUMCHANNELS);
    audiodata = zeros(info.TotalSamples, 1);
    [rowcurr,colcurr] = size(audiodata);
    fprintf('audiodata has %s rows and %s columns.\n',num2str(rowcurr),num2str(colcurr));
    reclen = length(audiodata)/(6000*60);
    fprintf('Length of recording: %s minutes\n',num2str(reclen));
    tslen = info.TotalSamples/(6000*60);
    fprintf('Total samples length: %s minutes\n',num2str(tslen));
    stepNum = 0;
    while ~isDone(h)
        stepNum = stepNum + 1;
        pct = (100 * stepNum / totalSteps);
        pct = num2str(pct, '%02f');
        pct = pct(1:5);
        pct = [pct '%'];
        disp(['Reading the ' num2str(info.NumChannels) '-channel .wav file ... ' pct]);
        try
            % read the audio frame (1,048,576 samples)
            % can also use [audio,eof] = step(h)
            % in this case, eof will be true if this is the last sample
            % unclear if this means eof is 1 or 'True' or something else
            % also check dimensions... What are rowLow and rowHigh?
            audio = step(h);
            rowLow = (stepNum - 1) * h.SamplesPerFrame + 1;
            if stepNum < totalSteps
                rowHigh = rowLow + h.SamplesPerFrame - 1;
                fprintf('rowHigh: %s; TotalSamples: %s\n',num2str(rowHigh),num2str(info.TotalSamples));
                fprintf('New data length: %s; space in array: %s\n',num2str(length(audio(:,whichchannel))),num2str(length(audiodata(rowLow:rowHigh))));
                %Why does audiodata get longer with each step?
                %Maybe this is inserting/appending rather than replacing?
                %Somehow change dimensions of audio(:,whichchannel) to match those of audiodata.
                audiodata(rowLow:rowHigh) = audio(:,whichchannel);
                [rowcurr,colcurr] = size(audiodata);
                fprintf('audiodata has %s rows and %s columns.\n',num2str(rowcurr),num2str(colcurr));
                reclencurr = length(audiodata)/(6000*60);
                fprintf('Current length of audiodata: %s minutes\n', num2str(reclencurr));
            else % Calculating rowHigh is different at the last step.
                reclen2 = length(audiodata)/(6000*60);
                fprintf('Penultimate length of audiodata: %s minutes\n', num2str(reclen2));
                rowHigh = rowLow + info.TotalSamples - (totalSteps * h.SamplesPerFrame) - 1;
                %Should be the same as info.TotalSamples
                clipSize = rowHigh - rowLow + 1;
                audiodata(rowLow:rowHigh) = audio(1:clipSize,whichchannel);
                reclen3 = length(audiodata)/(6000*60);
                fprintf('Final length of audiodata: %s minutes\n', num2str(reclen3));
            end
        catch ME
            if (strcmp(ME.identifier,'dspshared:system:libOutFromMmFile'))
                %"the audio input stream has become unresponsive"
                %fprintf(errorout, 'Issue with audio input stream.');
                %error('Issue with input stream for channel %s\n',channelNumber)
                error('There was an unknown issue with the audio input stream.');
            else
                ME.identifier
                rethrow(ME)
            end            
        end
    end
    audiowrite(outname,audiodata,info.SampleRate);
end
