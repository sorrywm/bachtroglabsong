%Change to directory where files are saved.
addpath 'D:/BackupFromDesktop072815/MATLABCode/Flysong/FlySongSegmenter';
addpath 'D:/BackupFromDesktop072815/MATLABCode';
listing=dir('*.wav');
filenames = {listing.name};
for i = 1:length(filenames)
    k=strfind(filenames{i},'filt');
    if isempty(k)
        FilterOnly(pwd,filenames{i},[],200);
    end
end