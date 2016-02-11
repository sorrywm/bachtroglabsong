function folderName = oldfindFolder(folderMap, maleSpecies, strain) %added strain and specified output as fullDir 6/4/15
    %switched to saving file to 'UnknownMaleSpecies' 11/17/15
    %folder = maleSpecies; %set a folder name in case no values match 6/4/15
    folder = 'UnknownMaleSpecies';
    allKeys = keys(folderMap);
    %also make a dictionary for the 'palli' names:
    strainMap = containers.Map();
    strainMap('pallidosa') = {'01','20001','"01"','"20001"','2001','".00"'};
    strainMap('pallidifrons') = {'PN175','pn175'};
    %check for palli first:
    inmalesp = strfind(maleSpecies, 'palli'); %also an option: 'palli '
    %if strcmp(maleSpecies,'palli') == 1 %replaced previous line 6/4/15
    if length(inmalesp) > 0
        %if strain == '01' || strain == 20001 %figure out what column the strain is
        %if strcmp(strain,'"01"') == 1 || strcmp(strain, '20001') == 1 %replaced previous line 6/4/15
        if sum(ismember(strainMap('pallidosa'),strain)) > 0
            folder = {'pallidosa'};
        elseif sum(ismember(strainMap('pallidifrons'),strain)) > 0
            %strain == 'pn175'  %^^find out strain (see above)
            %OR switch else and if so less work
            folder = {'pallidifrons'};
        else
            %folder = 'unknown'; 
            %this will trigger an error... but no longer necessary with new folder
        end
    else
        for key = allKeys
            %currentValues = values(folderMap, {key});
            currentValues = values(folderMap, key); %replaced previous line 6/4/15

            for value = currentValues
                innerval = value{1}; %added 6/4/15
                %length(innerval);
                %if maleSpecies == value
                if length(innerval) == 1
                    if strcmp(maleSpecies,innerval) == 1 
                        folder = key;
                    end
                else %loop over all possible values, added 6/4/15
                    for ival = innerval
                        if strcmp(maleSpecies,ival) == 1 
                            folder = key;
                        end
                    end
                end
            end
        end

        %fullDir = strcat(folderDir, folder); moved outside for loop 6/4/15
    end
    if strcmp(folder, 'UnknownMaleSpecies')
        fprintf('Problematic maleSpecies: %s\n', maleSpecies) %note that this is uncharacterized
    end
    folderName = char(folder);
end

