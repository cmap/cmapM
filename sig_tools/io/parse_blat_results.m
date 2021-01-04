% append Refseq ids and Genesymbols to BLAT output
% resFile: output of BLATs web interface (hyperlink output), OR
% output of parse_psl
% blatTable: refSeq lookup table 
function test = parse_blat_results(resFile, blatTable)

blat = parse_tbl(blatTable, 'detect_numeric', false);
test = parse_tbl(resFile, 'detect_numeric', false);
numq = length(test.QUERY);
blat_txEnd = str2double(blat.txEnd);
blat_txStart = str2double(blat.txStart);

test_TSTART = str2double(test.TSTART);
test_TEND = str2double(test.TEND);
test.HITS_REFSEQ = cell(numq,1);
test.HITS_GENESYM = cell(numq,1);
for idx=1:numq
    fprintf('%s\t chr%s%s %s %s %s %s %s',...
        test.QUERY{idx}, test.TNAME{idx}, test.STRAND{idx}, ...
        test.TSTART{idx}, test.TEND{idx}, test.IDENTITY{idx}, ...
        test.SCORE{idx}, test.SPAN{idx});     
    chrhits = cellfun(@length, ...
        regexp(blat.chrom, strcat('^chr',test.TNAME{idx},'$')))>0;
    strandhits = cellfun(@length, ...
        strfind(blat.strand,test.STRAND{idx}))>0;
    starthits = blat_txStart<=test_TSTART(idx);
    stophits = blat_txEnd >= test_TEND(idx);
    hits = find( chrhits & strandhits  & starthits & stophits); 
    hits_name = print_dlm_line(blat.name(hits),'fid', 1, 'dlm', '|');
    hits_name2 = print_dlm_line(blat.name2(hits), 'fid', 1, 'dlm', '|');
    if isempty(hits_name)
        hits_name = 'NO_HITS';
        hits_name2 = 'NO_HITS';
    end
    fprintf ('\t%s\t%s\n',hits_name, hits_name2);
    test.HITS_REFSEQ{idx} = hits_name;
    test.HITS_GENESYM{idx} = hits_name2;
end