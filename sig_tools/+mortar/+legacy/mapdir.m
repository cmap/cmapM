% map folders across unix, mac and windows folders and vice versa

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

% TOFIX: 
% - single word vs double word maps
% - cannot map windows paths to unix/mac
function name = mapdir(fname)

name = fname;
if ~isempty(name)
    if (ismac)
        % Volumes not appended already
        ismatch = regexp(name, '^/Volumes(/.+)','start');
        if (isempty(ismatch))
            [s,r] = strtok(name,'/');
            name = ['/Volumes/',s,regexprep(r,'/','_','once')];
        end
    elseif (isunix)
        [ismatch, tok] = regexp(name, '^/Volumes(/.+)', 'start','tokens');
        if (~isempty(ismatch))
            name = char(regexprep(tok{1},'_','/','once'));
        end
    elseif (ispc)
        % if drive letter specified do nothing
        has_drive_letter = ~isempty(regexp (name, ':'));
        if ~has_drive_letter
            % mac format
            [ismatch, tok] = regexp(name, '^/Volumes(/.+)', 'start','tokens');
            %mac to unix
            if (~isempty(ismatch))
                t = tokenize(tok{1}{1}, '/', true);
                %root
                root = t{2};
                rempath = t(3:end);
            else
                % unix path
                t = tokenize(name, '/', true);
                root = print_dlm_line2(t(2:3), 'dlm', '_');
                rempath = t(4:end);
            end
                drives = get_win_drives;
                driveidx = find(~cellfun(@isempty, regexp({drives.name}, root)));
                if isequal(length(driveidx), 1)
                    %path
                    name = print_dlm_line2([drives(driveidx).letter; rempath], 'dlm', '\\');
                end

            end
        end
    else
        disp ('Unknown folder mapping for current platform');
    end
end

