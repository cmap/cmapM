function id = sn2scanner(sn)
% SN2SCANNER Lookup Luminex scanner ids.
SCANNER_MAP = fullfile(mortarconfig('l1k_config_path'), 'scanners.txt');
if nargin && ~isempty(sn)
    info = parse_tbl(SCANNER_MAP, 'verbose', false);    
    % SN -> scanner-id
    m = containers.Map(info.serial_number, info.id);
    sn = strtrim(sn);
    if ischar(sn)
        sn = {sn};
    end
    n = length(sn);
    id = zeros(n,1);
    for ii=1:n
        if m.isKey(upper(sn{ii}))
            id(ii) = m(upper(sn{ii}));
        end
    end
end