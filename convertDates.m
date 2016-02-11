function convertDates(infile, datetype)
    %convert all dates in a .txt file to datetype
    %write to infile.datetype.txt
    inname = [infile '.txt'];
    outname = [infile '.' datetype '.txt'];
    ofid = fopen(outname,'a');
    ifid = fopen(inname,'rt');
    %read in infile
    while true
        dateArg = fgetl(ifid)
        if ~ischar(dateArg)
            fclose(ifid);
            break
        end
        switch length(dateArg)
            case 6
                outdate = datenum(dateArg, 'mmddyy');
            case 8
                outdate = datenum(dateArg, 'mmddyyyy');
            case 10
                outdate = datenum(dateArg, 'yyyy-mm-dd');
            otherwise
                warning('Issue with dateArg: %s', dateArg);
        end
        fprintf(ofid,'%s\n',datestr(outdate,datetype));
    end
    fclose(ofid)
end
