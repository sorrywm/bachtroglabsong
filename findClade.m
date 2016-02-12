function outclade = findClade(folderMap, cladeMap, maleSpecies, strain) %added strain and specified output as fullDir 6/4/15
    %switched to saving file to 'UnknownMaleSpecies' 11/17/15
    %also make a dictionary for the 'palli' names:
    folder = findFolder(folderMap, maleSpecies, strain);
    outclade = 'UnknownClade';
    cladeKeys = keys(cladeMap);
    for ckey = cladeKeys
        currentValues = values(cladeMap, ckey); %replaced previous line 6/4/15
        for value = currentValues
            innerval = value{1}; %added 6/4/15
            if length(innerval) == 1
                if strcmp(folder,innerval) == 1 
                    outclade = ckey;
                end
            else %loop over all possible values, added 6/4/15
                for ival = innerval
                    if strcmp(folder,ival) == 1 
                        outclade = ckey;
                    end
                end
            end
        end
    end
end
