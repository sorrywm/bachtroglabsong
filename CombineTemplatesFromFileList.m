function CombineTemplatesFromFileList(filelist, outfile)
%Perhaps switch to just combining two sets of templates at a time.
%Read in the list of files.
%Modify this such that the first column is a filename,
%and the second column is the list of signal templates.
load(filelist)
%Loop over the files, one at a time.
filetemplates = []
for f=1:length(file)
    load(files(f))
    %Append templates from this file to some list/array of templates.
    filetemplates = [filetemplates, newtemplates]
end
%Write the templates out with a new name.
newtemplates = filetemplates
save(outfile,'newtemplates')