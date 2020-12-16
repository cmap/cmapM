function test_suite = test_ds_aggregate
initTestSuite;
end

function td = setup
% common init
td = parse_gct(fullfile(mortarpath, 'unit_tests/assets/aggregate.gct'));
end

function teardown(td)
% common shutdown
end

function testAggregateColumn(td)

agg = ds_aggregate(td, 'col_fields', {'column_gp'}, 'fun', 'mean');
[~, gp, gpi]=get_groupvar(td.cdesc, td.chd, 'column_gp');

for ii=1:length(gp)
    cidx = strcmp(agg.cid, gp{ii});
    expect = mean(td.mat(:, gpi==ii), 2);
    assertElementsAlmostEqual(agg.mat(:, cidx), expect);
end
end

function testAggregateRow(td)

agg = ds_aggregate(td, 'row_fields', {'row_gp','row_gp2'}, 'fun', 'mean');
[~, gp, gpi]=get_groupvar(td.rdesc, td.rhd, {'row_gp','row_gp2'});

for ii=1:length(gp)
    ridx = strcmp(agg.rid, gp{ii});
    expect = mean(td.mat(gpi==ii, :), 1);
    assertElementsAlmostEqual(agg.mat(ridx, :), expect);
end

end




