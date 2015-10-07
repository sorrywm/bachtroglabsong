function ParseAllSongFiles(directory,tempfile,whichsignal,isshort,ipiptl)
%Modify this to the directory where you saved 'RunClusteringOneChannelFilt'
runclusterdir = 'D:/BackupFromDesktop072815/MATLABCode/Flysong/FlySongSegmenter/';

addpath(runclusterdir);

if nargin < 5 || isempty(ipiptl)
    ipiptl = 'IPI';
    if nargin < 4 || isempty(isshort)
        isshort = 'n';
    end
end

%cd(segmenterdir);
maxIPI=0.2;
splittempname = strsplit(tempfile,'/');
newtempoutname = splittempname{length(splittempname)};
%assume isshort = n, fs = 6000
wavfiles = dir( fullfile(directory,'*.wav') );
files = {wavfiles.name};
if numel(files) > 0
    for i=1:numel(files)
        fname = fullfile(directory,files{i});
        %Check first whether the file has already been parsed.
        clusterout = strcat(directory,'/',files{i},'_data',newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist.txt');
        if exist(clusterout,'file') ~= 2
            RunClusteringOneChannelFilt(fname,tempfile,whichsignal,isshort,6000,ipiptl);
        else
            sprintf('File has been generated:\n%s', clusterout);
        end
    end
else
    matfiles = dir( strcat(directory,'/*wav_data.mat') );
    %files = matfiles.name;
    if numel(matfiles) > 0
        for i=1:numel(matfiles)
            try
                matrec = matfiles(i);
                matfname = fullfile(directory,matrec.name);
            catch ME
                matfiles
                numel(matfiles)
                matfiles(i)
                rethrow ME
            end
            fname = strrep(matfname,'_data.mat',''); %convert to wav filename
            %Check first whether the file has already been parsed.
            clusterout = strcat(directory,'/',fname,'_data',newtempoutname,'signal',sprintf('%d',whichsignal),'maxIPI',num2str(maxIPI),'IPIdist.txt');
            if exist(clusterout,'file') ~= 2
                RunClusteringOneChannelFilt(fname,tempfile,whichsignal,isshort,6000,ipiptl);
            else
                sprintf('File has been generated:\n%s', clusterout);
            end
        end
    end
end
