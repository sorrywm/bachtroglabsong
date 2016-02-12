function justfilterExcelsheets(excelfile)
    %Filter an Excel file to include only dates where
    %recording notes indicate that someone was watching
    %and taking notes during the recording.
    %Sort by date possible?
    notesname = 'RecordingNotes'; %check this.... may not be right
    if exist(excelfile, 'file') == 2
        [pathstr,name,ext] = fileparts(excelfile);
        outname = fullfile(pathstr, [name 'Filtered.csv']); %can't write a .xlsx file unless Excel is installed.... possibly
        estable = readtable(excelfile);
        %sort by date
        try
            [establesort, index] = sortrows(estable, 'Date', 'ascend');
        catch MEsr
            disp(estable.Properties.VariableNames)
            rethrow(MEsr)
        end
        %get unique date values
        udates = unique(establesort.Date);
        %loop over unique date values
        for u=1:length(udates)
            keepdate = 0; %change to 1 if times found
            uind = strcmp(udates{u}, establesort.Date);
            minestab = establesort(uind,:);
            %try            
            %    minestab = establesort(establesort.Date == udates{u},:)
            %catch MEind
            %    fprintf('class(establesort.Date): %s; class(udates{u}: %s\n',...
            %            class(establesort.Date), class(udates{u}));
            %    disp(establesort.Date)
            %    rethrow(MEind)
            %end
            try
                keepdate = checkNotesTab(minestab, notesname);
            catch MEkd
                disp(minestab.Properties.VariableNames)
                rethrow(MEkd)
            end
            if keepdate == 1
                %add minestab to final table to write
                if exist('finaltab','var') ~= 1
                    %create finaltab
                    finaltab = minestab;
                else
                    finaltab = vertcat(finaltab, minestab);
                end
            end
        end
        if exist('finaltab', 'var') == 1
            writetable(finaltab, outname);
        else
            fprintf('No dates with notes found in %s\n', excelfile);
        end
    else
        fprintf('%s does not exist!\n',excelfile)
    end
end

function adddate = checkNotesTab(minitab,colname)
    %Looks for times in (Recording) Notes column
    %If present, adddate = 1, indicating to keep the spreadsheet
    %If absent, adddate = 0
    adddate = 0;
    for r=1:height(minitab)
        notestr = minitab{r,colname};
        hasnum = regexp(notestr,'-?\d+\.?\d*|-?\d*\.?\d+','match');
        if length(hasnum) > 0
            adddate = 1;
            break
        end
    end
end
