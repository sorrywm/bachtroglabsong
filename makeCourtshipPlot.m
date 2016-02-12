%someone not involved in the analysis, looking at the plot, what would the
%plot convey and what information would they get from the plot that could
%help their research/future experiments of assays
function makeCourtshipPlot()
    %This function is a wrapper that calls the subfunctions.
    [ta, na] = createArrays;
    ca = findCourtship(ta, na);
    createPlot(ta, ca);
end

function [tempArray, noteArray] = createArrays() 
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
    tempArray = [];
    %courtshipArray = [];
    noteArray = {};
    while (count < length + 1)  %+1 because need to start count at 1
        currentTemp = structByRow(count).Temp;
        currentTempInt = str2num(currentTemp);
        if (isempty(currentTempInt) == 1)
            currentTempInt = NaN;
        end
        tempArray = [tempArray, currentTempInt];
        currentNote = structByRow(count).RecordingNotes; %MATLAB removes space automatically
        %see T.Properties.VariableNames for all such conversions
        noteArray = [noteArray {currentNote}];
        count = count + 1; 
    end

end

function courtshipArray = findCourtship(tempArray, noteArray)  %temperature array from previous function^^
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
            %a
            %b = iscell(a)
            %c = iscell(a{1})
            %d = isempty(a{1})
            if (isempty(a{1}) == 0)  %0=false, a{1} not empty
                add = true;
            else    %isempty(a{1}) = 1 = true, a{1} is empty
                add = false;
            end 
        end
        if (add == true)
            courtshipArray = [courtshipArray, tempArray(i)];
            class(tempArray(i))
            tempArray(i);
        end
    end    
    
    %p = size(courtshipArray, 2);
    %p
    %courtshipArray(1:10)
end

function createPlot(tempArray, courtshipArray)
    %input: tempArray, courtshipArray (1 elem is an array of the temp and
    %courtship notes from that channel)
    %go through and count number of channels in a temp range that courted
    %from the courtshipArray
    %also count total number of channels in that temp range from the
    %tempArray
    %And then can plot 2 lines from each or a bar graph with 2 diff columns
    %can also output an array of the percentage of flies in that temp range
    %that courted --> easier to see a correlation perhaps with numbers than
    %analyzing the graph by eye
    %output: line graph w/ 1 line per array -- 1 line green, one blue
    %plot line of flies that courted at that temperature
    %and also plot line of flies that were tested overall at that
    %temperature
    
    %create legend for the graph
    %x-axis: temperature, y-axis: number of flies
    %y-difference between 2 lines are number of flies tested at that
    %temperature that didn't court

    
    tabulateTemp = tabulate(tempArray);
    %tabulateTemp
    %tabulateTemp(1,1)
    %tabulateTemp(1,2)
    %tabulateTemp(2,1)
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
    %class(tabulateTemp)
    %*********
    %use tabulate, 1st column is x-axis, 2nd column is y-axis
    %disregards NaN, not included in the table at all (good!!)
    %*********
    
    %tempArray(1:10)
    %courtshipArray(1:10)
    %temperature graph
    figure
    plot(xAxis, totalFlies, xAxis2, courtFlies, ':')
    title('Graphic Representation of Percentage that Successfully Courted at a Specific Temperature')
    xlabel('Temperature (degrees Celsius)')
    ylabel('Number of Flies (in pairs)')
    legend('Total Flies', 'Flies that Courted')
    %can add tempArray, totalArray, "--") to the end
    
    %percentage graph
    figure
    plot(xAxis3, percent)
    title('Percentage of Flies that Successfully Courted at a Specific Temperature')
    xlabel('Temperature (degrees Celsius)')
    ylabel('Percentage of Flies')
    legend('Percentage of Flies that Courted')
end    
%11/5
%change the table to add another column that is whether or not they courted
%and just say yes or no and then export it as a new excel file or modified
%excel file after
%easy to check that it works and could also be used for something else
%later
%linear graph first and then send to melissa and cc wynn
%bar graph w/o bin temps, instead get rid of digits after decimal point
%matlab built in function --> for looking at column and tell how many
%unique elements there are


%not in current pipeline, return to later
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