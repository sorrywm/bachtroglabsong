function verifyPath(folderPath, i)
    global EXCLUDECHANNELS;
    if ismember(i, EXCLUDECHANNELS)
        return;
    end
    global FEEDBACK;
    switch exist(folderPath, 'dir')
        case 0
            % A folder for this species does not exist.
            FEEDBACK = [FEEDBACK; ['ERROR: The folder ' folderPath ' does not exist.']];
            FEEDBACK = [FEEDBACK; ['ERROR: Create ' folderPath ' and run script again.']];
            FEEDBACK = [FEEDBACK; ['ERROR: No files were saved!!!']];
            disp(FEEDBACK);
            disp(folderPath);
            error('There was an error. See feedback above.');
        case 7
            % The folder exists! Continue.
        otherwise
            % Unknown conflict with path name for this species.
            FEEDBACK = [FEEDBACK; ['WARNING: The folder path ' folderPath ' caused an unknown problem. Files for this species may not be saved!!!']];
    end
end

