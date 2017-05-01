function [isok, bad_files, rpt] = check_lxb(lxb_path)
% CHECK_LXB Check a folder of LXB files for readability.

[fn ,fp] = find_file(fullfile(lxb_path, '*.lxb'));

rpt = struct('file_name', fn,...
             'file_path', fp,...
             'is_ok', true);
nf = length(fn);

parfor ii=1:nf
    try
        lxb = parse_lxb(fp{ii});
    catch me
        dbg(1, '%s %s:%s', fn{ii}, me.identifier, me.message);
        rpt(ii).is_ok = false;
    end
end

isok = all([rpt.is_ok]);
bad_files = {rpt(~[rpt.is_ok]).file_path}';

end