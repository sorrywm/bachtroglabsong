function tablesortIntoClades(excelfile, clade)
    %write out separate excel files for each clade
    %current header range is set up for file resulting from python combine script
    %global FOLDERMAPFILE;
    FOLDERMAPFILE = '/global/home/users/wynn/repos/bachtroglabsong/folderMap.mat';
    clademap = '/global/home/users/wynn/repos/bachtroglabsong/cladeMap.mat';
    [pathstr,name,ext] = fileparts(excelfile);
    outname = fullfile(pathstr, [name clade '.csv']);
    %outdata = [];

    %read excelfile as table
    raw = readtable(excelfile);
    %raw.Properties.VariableNames
    %replace all commas in RecordingNotes column
    for i=1:height(raw)
        raw{i,'RecordingNotes'} = strrep(raw{i,'RecordingNotes'},',',';');
        raw{i,'OtherFemales_'} = strrep(raw{i,'OtherFemales_'},',',';');
        raw{i,'OtherMales_'} = strrep(raw{i,'OtherMales_'},',',';');
        raw{i,'Virgin_'} = strrep(raw{i,'Virgin_'},',',';');
        raw{i,'FertilityAssayed_'} = strrep(raw{i,'FertilityAssayed_'},',',';');
        raw{i,'Time'} = strrep(raw{i,'Time'},',',';');
    end
    %load folderMap and cladeMap
    folderMap = getfolderMap(FOLDERMAPFILE);
    keys(folderMap)
    cladeMap = getcladeMap(clademap);
    %loop through rows
    for r=1:height(raw)
        %get 'folder' (species) for row
        maleSpecies = raw{r,'Species_1'};
        if isnumeric(maleSpecies)
            maleSpecies = num2str(maleSpecies);
        end
        %Strip spaces from the string.
        try
            maleSpecies = strtrim(maleSpecies);
        catch ME
            error(['issue with maleSpecies :' maleSpecies ', ' class(maleSpecies)])
        end
        maleStrain = raw{r,'Strain_1'};
        if isnumeric(maleStrain)
            maleStrain = num2str(maleStrain);
        end
        maleStrain = strtrim(maleStrain);
        %get clade from folder
        cladeName = findClade(folderMap, cladeMap, maleSpecies, maleStrain);
        %write row to outfile
        if strcmp(cladeName,clade)
            %outdata = [outdata; raw(r,1:maxcol)];
            %outdata = [outdata; raw(r,:)];
            if exist('outdata','var') ~= 1
                %create outdata
                outdata = raw(r,:);
            else
                outdata = vertcat(outdata, raw(r,:));
            end
        end
    end
    if height(outdata) > 0
        %xlswrite(outname, outdata);
        %cell2csv(outname, outdata);
        %csvwrite(outname, outdata);
        writetable(outdata, outname)
    else
        fprintf('%s not found in %s\n',clade,excelfile);
    end
end
