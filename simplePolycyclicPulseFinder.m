function simplePolycyclicPulseFinder(wavfile, filtcut, minLength)
    %very simple code to find pulses in polycyclic song
    %dependencies: gmixPlot, sampleFromMatrix, returnCellLengths
    %performs Gaussian smoothing over all peaks
    %use AIC to determine number of components of mixture
    %runs a Gaussian mixture model for amplitude
    %assumes the component with the highest mean represents true song (not
    %noise)
    %identifies pulses as local maxima in regions at least minLength in length
    %estimates IPI from these local maxima
    if nargin < 2
        filtcut = 200;
    end
    if nargin < 3
        minLength = 10;
    end
    [y,Fs] = audioread(wavfile);
    [b,a]=butter(10,filtcut./(Fs/2),'high');
    y2 = filtfilt(b,a,y);
    y3 = gaussianfilterdata(abs(y2),10); %Does this parameter need to be tuned?
    
    obj=gmixPlot(sampleFromMatrix(log10(y3(1:100000)),10000),3,[],100,false,true);
    %check to see which gaussian is the furthest to the right ? below assumes 3

    posts = posterior(obj,log10(y3));
    posts = posts(:,3);

    mask = posts(:,3) > .5;
    mask = posts > .5;

    CC = bwconncomp(mask);
    lengths = returnCellLengths(CC.PixelIdxList);
    smallValues = find(lengths < minLength);
    for j=1:length(smallValues)
    mask(CC.PixelIdxList{smallValues(j)}) = false;
    end

    figure,plot(y2)
    hold on
    plot(y3.*double(mask),'r-','linewidth',1)
    y4 = y3.*double(mask);

    maxes = find(imregionalmax(y4));

    figure
    hold on
    for i=1:length(maxes)
    plot(maxes(i) + [0 0],[-2 2],'k--')
    end

    IPIs = diff(maxes)*1000/Fs;
    figure
    hist(IPIs(IPIs < 100),100)
end