function test_suite = testParseParam
initTestSuite;
end

function td = setup
% common init

td = struct('infile', fullfile(mortarpath, 'unit_tests/assets/test_01.param'));
    
end

function teardown(td)
% common shutdown

end

function testParser(td)
% Read a parameter file and check results.

ref = struct('plate', 'GJA102_XC_XH_X1_NB1_DUO52HI53LO',...
'scan_date', '3/28/2013 9:40 AM',...
'scan_duration', '6h 50m',...
'scanner_name', 'Scanner 0',...
'scanner_sn', 'FM3DD12171003',...
'bset', 'dp52,dp53',...
'csv_path', '/cmap/projects/ncdata/curated/GJA102_XC_XH_X1_NB1_DUO52HI53LO/GJA102_XC_XH_X1_NB1_DUO52HI53LO.csv',...
'missing_analytes', 'dp53:11,dp52:499',...
'notduo', '[1:10,11,499]',...
'cell_array', {{'foo'; 'bar'}},...
'scalar', {100},...
'numeric_array',{[1;2;3]},...
'string', '100',...
'boolean_1', true,...
'boolean_2', false,...
'boolean_3', true,...
'boolean_4', false);

res = parse_param(td.infile);

assertEqual(length(fieldnames(ref)), length(fieldnames(res)), 'Number of fieldnames dont match');

ref_fn = fieldnames(ref);
res_fn = fieldnames(res);
nfn = length(ref_fn);
for ii=1:nfn
    assertEqual(ref_fn{ii}, res_fn{ii}, 'Fieldname mismatch');
    assert(isequal(ref.(ref_fn{ii}), res.(res_fn{ii})), sprintf('Field value mismatch for field %s', ref_fn{ii}));
end

end




