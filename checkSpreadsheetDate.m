function [datematch, probrow] = checkSpreadsheetDate(desdate, ssraw, wrows)
    % check to make sure the dates in a spreadsheet are the same
    % as in the spreadsheet name
    % start with the (already read) raw data from the spreadsheet
    % use EXCLUDECHANNELS and NUMCHANNELS to determine which rows to check.
    datematch = 1;
    probrow = 'NaN';
    for i=1:length(wrows)
        dateRaw = ssraw{wrows(i), 1}; %date may not be text format
        if strcmp(dateRaw, '') || strcmp(dateRaw, 'NA') || sum(isnan(dateRaw)) > 0
            datematch = 0;
            probrow = 1;
        else
            try
                if isnumeric(dateRaw)
                    dateNum = datenum(x2mdate(dateRaw));
                    dateString = datestr(dateNum, 'yyyy-mm-dd');
                elseif ischar(dateRaw)
                    %set date to zero if 'notes' in this column
                    notefind = strfind(dateRaw,'otes');
                    if length(notefind) == 0
                        dateNum = datenum(dateRaw, 'mm/dd/yyyy');
                        dateString = datestr(dateNum, 'yyyy-mm-dd');
                    else
                        dateString = '0000-00-00';
                    end
                else
                    error('Issue with type of dateRaw %s.',class(dateRaw))
                    exit
                end
            catch ME
                if isnumeric(dateRaw)
                    firstrowmsg = ['Issue with dateRaw for ',desdate,': ', num2str(dateRaw), ', class: ', class(dateRaw)]
                else
                    firstrowmsg = ['Issue with dateRaw for ',desdate,': ', dateRaw, ', class: ', class(dateRaw)]
                end
                msg = [firstrowmsg, '\n', ...
                      'contents of 2nd column: ', ssraw{i, 2}, ', class: ', class(ssraw{i, 2}), '\n',...
                      'contents of 3rd column: ', ssraw{i, 3}, ', class: ', class(ssraw{i, 3}), '\n',...
                      'contents of 4th column: ', ssraw{i, 4}, ', class: ', class(ssraw{i, 4}), '\n',...
                      'contents of 5th column: ', ssraw{i, 5}, ', class: ', class(ssraw{i, 5}),'\n'];
                causeException = MException('MATLAB:myCode:dateRaw',msg);
                ME = addCause(ME,causeException);
                rethrow(ME)
            end
        end
        %Check dateString against desdate:
        if ~strcmp(desdate,dateString)
            datematch = 0;
            probrow = wrows(i);
            break
        end
    end
end
