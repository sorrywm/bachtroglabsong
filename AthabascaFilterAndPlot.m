newlisting=dir('J:/SoundData/AthabascaRecordings/Cross*');
for c=1:length(newlisting)
listing=dir(strcat('J:/SoundData/AthabascaRecordings/',newlisting(c).name,'/*.wav'));
for l=1:length(listing)
FilterAndPlot(strcat('J:/SoundData/AthabascaRecordings/',newlisting(c).name),listing(l).name,[],6000);
end
end