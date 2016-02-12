function excelFileArr = findExcelFileArr()
%modified from makeWaves_savio_raw.m
    global SPREADSHEETPATH; %need to define these global variables within other script
    global EXCELNAMESCHEME;
    global DATETODAY;
    global DATEFORMAT;
    global DATEFORMAT2;
    global DATEFORMAT3;
    %disp(DATETODAY)
    dateToday = datestr(DATETODAY, DATEFORMAT);
    dateToday2 = datestr(DATETODAY, DATEFORMAT2);
    try
        dateToday3 = datestr(DATETODAY, DATEFORMAT3);
    catch MEdT3
        fprintf('Issue with dateToday3; DATETODAY: %s, DATEFORMAT3: %s\n',DATETODAY,DATEFORMAT3);
        rethrow(MEdT3)
    end
    downloads = dir(fullfile(SPREADSHEETPATH, EXCELNAMESCHEME));
    downloadedRecordings = {};
    for i = 1:length(downloads)
        %may need to modify other instances of findstr
        datein = strfind(downloads(i).name, dateToday);
        datein = [datein strfind(downloads(i).name, dateToday2)];
        %datein = [datein strfind(downloads(i).name, dateToday3)];
        %Require 'g' or 's' to precede dateToday3 (otherwise could get wrong date)
        datein = [datein strfind(downloads(i).name, strcat('s',dateToday3))];
        datein = [datein strfind(downloads(i).name, strcat('g',dateToday3))];
        if length(datein) > 0       
            downloadedRecordings = [downloadedRecordings; downloads(i).name];
        end
    end
    switch length(downloadedRecordings)
        case 0
            % no file
            error(['There is no Excel file with a name including ' ...
                dateToday ' or ' dateToday2 ' in ' fullfile(SPREADSHEETPATH, EXCELNAMESCHEME) ...
                '. Please download the spreadsheet for this day.']);
        case 1
            % go for it
            excelfilename = [SPREADSHEETPATH downloadedRecordings{1}];
            excelFileArr = {excelfilename};
        case 2
            % save both filenames
            file1 = [SPREADSHEETPATH downloadedRecordings{1}];
            file2 = [SPREADSHEETPATH downloadedRecordings{2}];
            excelFileArr = {file1 file2};
            excelFileArr = sort(excelFileArr); 
        otherwise
            % multiple files
            error(['There are more than two Excel files with a name including ' ...
                dateToday '. Please download only one to two at a time.']);
    end
end
