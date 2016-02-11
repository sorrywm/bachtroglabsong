function debugbin2wav(filename)
addpath('/global/home/users/wynn/repos/omnivore');
[y,fs,nbits]=binread([filename '.bin']);
try
    audiowrite([filename '.wav'],y,floor(fs),'BitsPerSample',nbits);
catch MEaw
    fprintf('Fs: %s; class: %s',fs,class(fs));
    rethrow(MEaw)
end
