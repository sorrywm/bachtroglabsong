function makeCourtshipPlotGeneric(testVar)  %string of column name
    %This function is a wrapper that calls the subfunctions.
    %if testVar is 'humidity' or 'temp' or '...'
    %testVar is case sensitive
    
    [var, note] = createArrays(testVar);  %var must always be int array
    court = findCourtship(var, note);
    createPlot(var, court, testVar);
end

function [varArray, noteArray] = createArrays(varName) 
    %inputs can be made based on variables needed after generalization
    %change file and path depending on where file is stored
    file = 'AllRecordingsThrough051915test.xlsx';
    
    T = readtable(file); %everything is a string, var1 = dummy variable
    structByRow = table2struct(T);  %create struct where each col is a field
    
    %now extract individual arrays for humidity and temp for now
    disp(structByRow); %also shows variable names
    length = 0;    
    [m, n] = size(structByRow);
    if (m == 1) 
        length = n;
    else
        length = m;
    end
    %Now create temp array by looping through struct to get temp
    count = 1;
    %courtshipArray = [];
    noteArray = {};
    while (count < length + 1)  %+1 because need to start count at 1
        currentNote = structByRow(count).RecordingNotes; %MATLAB removes space automatically
        %see T.Properties.VariableNames for all such conversions
        noteArray = [noteArray {currentNote}];
        count = count + 1; 
    end
    if (strcmp(varName, 'Temp'))
        varArray = createTempArray(length, structByRow);
    elseif (strcmp(varName, 'Humidity'))
        varArray = createHumidityArray(length, structByRow);
    %elseif (strcmp(varName, ''))
        %varArray = create____Array(structByRow);
    end

end

function tempArray = createTempArray(length, structByRow)
    count = 1;
    tempArray = [];
    while (count < length + 1)  %+1 because need to start count at 1
        currentTemp = structByRow(count).Temp;
        currentTempInt = str2num(currentTemp);
        if (isempty(currentTempInt) == 1)
            currentTempInt = NaN;
        end
        tempArray = [tempArray, currentTempInt];
        %see T.Properties.VariableNames for all such conversions
        count = count + 1; 
    end
end

function humidityArray = createHumidityArray(length, structByRow)
    count = 1;
    humidityArray = [];
    while (count < length + 1)  %+1 because need to start count at 1
        currentHumidity = structByRow(count).Humidity;
        currentHumidityInt = str2num(currentHumidity);
        if (isempty(currentHumidityInt) == 1)
            currentHumidityInt = NaN;
        end
        humidityArray = [humidityArray, currentHumidityInt];
        %see T.Properties.VariableNames for all such conversions
        count = count + 1; 
    end
end


function courtshipArray = findCourtship(varArray, noteArray)  %temperature array from previous function^^
    %input: sortedArray of temperature(1 x # of entries in spreadsheet)
    %and sortedArray of recording notes or 1 array together w/2 diff fields
    %output: new array of temps for flies that courted (1 x # of channels 
    %where flies courted)
    
    courtshipArray = [];
    %may need to also check for uppercase versions of words bc strfind is
    %case sensitive
    wordArray = ['court']; %'copulate', 'copulation';
    m = size(noteArray, 2);  %length of array
    for i = 1:m 
        for j = 1:1
            a = strfind(noteArray(i), wordArray(j));
            if (isempty(a{1}) == 0)  %0=false, a{1} not empty
                add = true;
            else    %isempty(a{1}) = 1 = true, a{1} is empty
                add = false;
            end 
        end
        if (add == true)
            courtshipArray = [courtshipArray, varArray(i)];
            class(varArray(i))
            varArray(i);
        end
    end    
end

function createPlot(varArray, courtshipArray, varName)
    %input: tempArray, courtshipArray (1 elem is an array of the temp and
    %courtship notes from that channel)
    %output: line graph w/ 1 line per array -- 1 line green, one blue
    %plot line of flies that courted at that temperature
    %and also plot line of flies that were tested overall at that
    %temperature

    %use tabulate, 1st column is x-axis, 2nd column is y-axis
    %disregards NaN, not included in the table at all
    
    tabulateTemp = tabulate(varArray);
    xAxis = tabulateTemp(1:31, 1);
    totalFlies = tabulateTemp(1:31, 2);
    %courtshipArray
    tabulateCourt = tabulate(courtshipArray);
    %tabulateCourt
    xAxis2 = tabulateCourt(1:31, 1);
    courtFlies = tabulateCourt(1:31, 2);
    
    xAxis3 = tabulateCourt(1:31, 1);
    percent = [];
    for i = 1:31
        courtFlies(i)
        totalFlies(i)
        p = (courtFlies(i)/totalFlies(i))*100;
        p;
        percent = [percent p];
    end
    percent

    figure
    plot(xAxis, totalFlies, xAxis2, courtFlies, ':')
    title(strcat('Graphic Representation of Percentage that Successfully Courted at a Specific', varName))
    xlabel(varName)
    ylabel('Number of Flies (in pairs)')
    legend('Total Flies', 'Flies that Courted')
    %can add tempArray, totalArray, "--") to the end
    
    %percentage graph
    figure
    plot(xAxis3, percent)
    title(strcat('Graphic Representation of Percentage that Successfully Courted at a Specific', varName))
    xlabel(varName)
    ylabel('Percentage of Flies')
    legend('Percentage of Flies that Courted')
end    





%not in current pipeline, return to later if necessary
function sortTempArray() %or the variable I'm currently analyzing

    %input: 
    %output: 

    %determine cutoffs for sorting temperature
    firstElem = sortedTempArray(0);  %are these strings? --> import as ints
    lastElem = sortedTempArray(length - 1);
    range = lastElem - firstElem;
    bin = range/3;
    %create lo, mid, and hi arrays based on bin cutoff
    %%WM: Maybe plot the distribution of temp and see if there are
    %%WM: natural ranges/cutoffs.
    %%WM: Or use quantiles....
    
    %make sure that while sorting temperature array, that also sorting courtship
    %array so that it matches up    
    %could also use merge sort to sort the array first and then separate
    %it into 3 smaller arrays based on cutoffs that I found

    %rearrange struct by temp into new struct?
    
    
end

%return the info for each fly in each of the 3 groups

%in another function, analyze which flies seem to occur most often in each
%group based on the temp
%later, see if there is an easy way to generalize this in stead of having a
%bunch of different specific functions
%%WM: Maybe you can have the column name you want to sort by 
%%WM: be one of the input variables?