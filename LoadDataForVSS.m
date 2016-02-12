%Change the range to 11900000:13900000
%song=load('/Volumes/WynnHD/songfiles/americanaegoutput/20150610T102054a_13.wav_data.mat','d')
%testsong=song.d(14196699:16196699);
%testsong=song.d(11900000:13900000);
[song, Fs] = audioread('/Volumes/WMSeagateExpansion/songfiles/Channel13_061015a_americana.wav');
testsong = song(11900000:13900000);
tic
[maleBoutInfo,femaleBoutInfo,run_data]=segmentVirilisSong([testsong],[],6000)
toc
%save('/Volumes/WynnHD/songfiles/americanaegoutput/VSSOutputLast2M.mat',...
save('/Volumes/WMSeagateExpansion/songfiles/VSSOutput2MDuetCentered.mat',...
    'femaleBoutInfo','maleBoutInfo','run_data');
savefig('/Volumes/WMSeagateExpansion/songfiles/VSSOutput2MDuetCenteredPlot.fig');