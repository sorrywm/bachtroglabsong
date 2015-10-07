function CombineTemplates(tempfile1, whichsignal1, tempfile2, whichsignal2, outname)
%Perhaps switch to just combining two sets of templates at a time.
%Currently wrong output dimensions.
%From createTemplates.m:
%%templates -> L x 1 cell array containing M_i x d arrays of template peaks
%Get 'newtemplates' from the first file.
load(tempfile1)
%Subset this to just get signal templates.
signaltemplates={};
for i = 1:length(whichsignal1)
    signaltemplates{length(signaltemplates)+1} = newtemplates{whichsignal1(i)};
end    
load(tempfile2)
for j = 1:length(whichsignal2)
    signaltemplates{length(signaltemplates)+1} = newtemplates{whichsignal2(j)};
end
display(length(signaltemplates))
%Write the templates out with a new name.
newtemplates = signaltemplates;
save(outname,'newtemplates');