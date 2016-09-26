function badfilelist = testfor60hzhum(testobj, humfreq)
    %Run a PSD analysis and test whether there are local maxima
    %at multiples of 60 (humfreq can be specified 50 Hz for Europe). 
    %May require more tinkering with filters on peak finding.
    %Report all files with this property.
    %If testobj is a directory, loop through .wav files in directory.
    if nargin < 2 || isempty(humfreq)
        humfreq = 60;
    end
    warning('off', 'signal:findpeaks:largeMinPeakHeight');
    badfilelist = {};
    if exist(testobj, 'dir') == 7
        %run loop
        tfiles = dir(fullfile(testobj, '*.wav'));
        for tf=1:length(tfiles)
            possbadfile = testonesong(fullfile(testobj,tfiles(tf).name), humfreq);
            if ~isempty(possbadfile)
                badfilelist{length(badfilelist)+1} = possbadfile;
            end
        end
    elseif exist(testobj,'file') == 2
        %assume single file
        possbadfile = testonesong(testobj, humfreq);
        if ~isempty(possbadfile)
            badfilelist = {possbadfile};
        end
    else
        error('Must specify a valid directory or .wav filename\n');
    end
end

function filenameifbad = testonesong(songfile, humfreq)
    filenameifbad = {};
    [tsong,fs] = audioread(songfile);
    [pxx,f] = pwelch(tsong,[],[],[],fs);
    %The following line may need to be tweaked a bit:
    [~,locs] = findpeaks(pxx,'MinPeakWidth',2,'MinPeakHeight',1e-4);
    for l=1:length(locs)
        freqmax = round(f(locs(l)));
        if abs(round(freqmax/humfreq)-freqmax/humfreq)*humfreq < 2 && freqmax >= (humfreq - 1)
            fprintf(['%s\n may have mains hum (local maximum frequency at'...
            ' %d Hz)\n'],songfile,freqmax);
            filenameifbad = songfile;
            break
        end
    end
end