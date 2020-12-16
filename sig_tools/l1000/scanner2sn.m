function sn = scanner2sn(id)
% SCANNER2SN Lookup Luminex scanner serial numbers.
SCANNER_MAP = fullfile(mortarconfig('l1k_config_path'), 'scanners.txt');
if nargin && ~isempty(id)
    info = parse_tbl(SCANNER_MAP, 'verbose', false);    
    % scanner-id -> SN
    m = containers.Map(info.id, info.serial_number);
%     return_char = false;
%     if ischar(id)
%         id = {id};
%         return_char = true;
%     end
    n = length(id);
    sn = cell(n,1);
    for ii=1:n
        if m.isKey(id(ii))
            sn{ii} = m(id(ii));
        else
            sn{ii} = '';
        end
    end    
%     if return_char
%         sn = sn{1};
%     end
end