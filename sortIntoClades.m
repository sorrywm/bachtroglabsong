function sortIntoClades(excelfile, clade)
    %write out separate excel files for each clade
    %current header range is set up for file resulting from python combine script
    %global FOLDERMAPFILE;
    FOLDERMAPFILE = '/global/home/users/wynn/repos/bachtroglabsong/folderMap.mat';
    clademap = '/global/home/users/wynn/repos/bachtroglabsong/cladeMap.mat';
    [pathstr,name,ext] = fileparts(excelfile);
    outname = fullfile(pathstr, [name clade '.csv']);
    outdata = [];

    %read in header
    [~,~,header] = xlsread(excelfile, 'Sheet1', 'A1:AC1', 'basic');
    %find maleSpecies and maleStrain columns
    %spindex = find(strcmp(header, 'Species'));
    %stindex = find(strcmp(header, 'Strain'));
    %spindex = strfind(header, 'Species');
    %stindex = strfind(header, 'Strain');
    %spindex = find(cellfun('length',regexp(header,'Species')) == 1);
    %stindex = find(cellfun('length',regexp(header,'Strain')) == 1);
    spindex = [23 24];
    stindex = [25 26]; %to generalize this, find a way to search a cell array with missing values for a string
    %read in excelfile
    [~,~,raw] = xlsread(excelfile);
    %outdata = [raw(1,:)]
    %maxcol = length(outdata)
    %load folderMap and cladeMap
    folderMap = getfolderMap(FOLDERMAPFILE);
    keys(folderMap)
    cladeMap = getcladeMap(clademap);
    %loop through rows
    [nrows, ncolumns] = size(raw);
    for r=1:nrows
        %get 'folder' (species) for row
        maleSpecies = raw{r, spindex(2)};
        if isnumeric(maleSpecies)
            maleSpecies = num2str(maleSpecies);
        end
        %Strip spaces from the string.
        try
            maleSpecies = strtrim(maleSpecies);
        catch ME
            error(['issue with maleSpecies :' maleSpecies ', ' class(maleSpecies)])
        end
        maleStrain = raw{r, stindex(2)};
        if isnumeric(maleStrain)
            maleStrain = num2str(maleStrain);
        end
        maleStrain = strtrim(maleStrain);
        %get clade from folder
        cladeName = findClade(folderMap, cladeMap, maleSpecies, maleStrain);
        %write row to outfile
        if strcmp(cladeName,clade)
            %outdata = [outdata; raw(r,1:maxcol)];
            outdata = [outdata; raw(r,:)];
        end
    end
    if length(outdata) > 0
        xlswrite(outname, outdata);
        %cell2csv(outname, outdata);
        %csvwrite(outname, outdata);
    else
        fprintf('%s not found in %s\n',clade,excelfile);
    end
end
