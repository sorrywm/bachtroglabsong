function plotParameterHist(values, hbreaks, parname, xaxlabel, plotoutname)
    %Plot histogram of values using hbreaks breaks.
    %Save as plotoutname
    %Multiply by 1000 for IPI/PTL, not for PPB.
    if hbreaks > length(values)/10
        hbreaks = max(round(length(values)/10),10);
    end
    %[Y,X] = hist(values, hbreaks); 
    %Y = Y  ./ (sum(Y)*(X(2)-X(1)));
    %plot(X*1000,Y)
    %switch to 'histogram' in more recent releases of MATLAB
    if strcmp(parname, 'IPI') || strcmp(parname, 'PTL')
        values = values*1000;
    end
    histogram(values, hbreaks);
    title(strcat(parname,' histogram'))
    xlabel([xaxlabel ' (N=' num2str(length(values)) ')'])
    ylabel ('Count')
    try
        saveas(gcf, plotoutname);
    catch MEplotname
        disp(plotoutname)
        rethrow(MEplotname)
    end
end