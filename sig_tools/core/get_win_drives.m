% GET_WIN_DRIVES Get drive information in MS-Windows.
function drives = get_win_drives
drives = [];
if ispc
    %     [status, s] =system('net use');
    %     lines = textscan(s, '%s', 'delimiter', char(10));
    %     % connected drives
    %     isconnected = strmatch('OK', lines{1});
    %     nconnected  = length(isconnected);
    %     local = cell(nconnected, 1);
    %     remote = local;
    %     for ii=1:nconnected
    %         tok=textscan(lines{1}{isconnected(ii)}, '%s',...
    %             'delimiter', ' ', 'multipledelimsasone',1);
    %         local{ii} = tok{1}{2};
    %         remote{ii} = tok{1}{3};
    %     end
    roots = java.io.File.listRoots();
    nroot = length(roots);
    drives = struct('letter', cell(nroot,1),...
        'name', cell(nroot, 1),...
        'type', cell(nroot, 1));
    for ii=1:nroot
        drives(ii).letter = strrep(char(roots(ii)), '\', '');
        drives(ii).name = char(javax.swing.filechooser.FileSystemView.getFileSystemView().getSystemDisplayName(roots(ii)));
        drives(ii).type = char(javax.swing.filechooser.FileSystemView.getFileSystemView().getSystemTypeDescription(roots(ii)));
    end
end

