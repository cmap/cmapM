function [ds, series_rpt] = parse_geo_series(infile)
% PARSE_GEO_SERIES Read serties matrix file from GEO
% [DS, RPT] = PARSE_GEO_SERIES(INFILE) returns the series matrix as an
% annotated dataset DS and the series annotation as a structure RPT

fid = fopen(infile, 'rt');
% Sample annotations
sample_dict = mortar.containers.Dict();
% Series annotations
series_dict = mortar.containers.Dict();

while fid>0 && ~feof(fid)
    line = fgetl(fid);
    isseries_meta = strncmp(line, '!Series_', 8);
    issample_meta = strncmp(line, '!Sample_', 8);
    is_matrix_begin = strcmp(line, '!series_matrix_table_begin');
    %is_matrix_end = strcmp(line, '!series_matrix_table_end');
    if is_matrix_begin
        sample_rpt = cell2struct(sample_dict.values,...
                            validvar(sample_dict.keys), 2);
        series_rpt = cell2struct(series_dict.values,...
                            validvar(series_dict.keys), 2);
        dbg(1, '%s %s', series_rpt.series_geo_accession{1},...
                        series_rpt.series_title{1});
        
        ds = parse_matrix(fid, sample_rpt);
    elseif issample_meta
        [key, val] = parse_keyval(line);
        if sample_dict.isKey(key)
            oldval = sample_dict(key);
            val = paste([oldval{1}, val], '|');
        end
        sample_dict(key) = val;
    elseif isseries_meta
        [key, val] = parse_keyval(line);
        if series_dict.isKey(key)
            oldval = series_dict(key);
            val = paste([oldval{1}, val], '|');
        end
        series_dict(key) = val;        
    end
end

fclose(fid);
end

function [key, val] = parse_keyval(line)
    %line = regexprep(line, '^[! \r\n]+', '');
    line = regexprep(line, '[ \r\n]+$', '');
    tok = textscan(line, '%q', 'MultipleDelimsAsOne', true);
    tok = tok{1};
    ntok = length(tok); 
    key = lower(strrep(tok{1}, '!', ''));
    val = tok(2:end);
end

function ds = parse_matrix(fid, sample_rpt)
    
    has_row_count = isfield(sample_rpt,'sample_data_row_count');
    assert(has_row_count, 'No row count found');    
    nrow = str2double(sample_rpt.sample_data_row_count{1});    
    head_line = fgetl(fid);
    [id, cid] = parse_keyval(head_line);
    ncol = length(cid);
    rid = cell(nrow, 1);
    mat = nan(nrow, ncol);
    dbg(1, 'Matrix dimensions [%d x %d]', nrow, ncol);
    for ii=1:nrow
        line = fgetl(fid);
        [rid{ii}, x] = parse_keyval(line);
        mat(ii, :) = str2double(x);        
    end
    ds = mkgctstruct(mat, 'rid', rid, 'cid', cid);
    chd = fieldnames(sample_rpt);
    for ii=1:length(chd)
        ds = ds_add_meta(ds, 'column', chd{ii}, sample_rpt.(chd{ii}));
    end
end