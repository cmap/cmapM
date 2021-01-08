function test_suite = testSigQueryTool
initTestSuite;
end

function td = setup
% common init
    td = struct('uptag', fullfile(mortarpath, 'unit_tests/assets/science_cmap_up.gmt'),...
        'dntag', fullfile(mortarpath, 'unit_tests/assets/science_cmap_dn.gmt'));
end

function teardown(td)
% common shutdown

end

function testExtTagQueryWTCS(td)
%% External query with tags, WTCS, full row_space
% HDAC Glaser query -> trichostatin-A connection

up = parse_geneset(td.uptag);
dn = parse_geneset(td.dntag);
tagidx = find(strcmp('HDAC_UP', {up.head}));

% expected results
ref = struct('score', single(0.7733),...
             'up_score', single(0.7449),...
             'dn_score', single(-0.8016));
         
cid = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};

[qo, result] = sig_query_tool('build_id', 'a2', 'metric', 'wtcs',...
                'row_space', 'full', 'uptag',up(tagidx),'dntag',dn(tagidx),...
                'cid', cid, 'save_analysis', false);

assertEqual('wtcs', result.metric);            
assertElementsAlmostEqual(ref.up_score, result.score(1,1,1), 'UP score mismatch');
assertElementsAlmostEqual(ref.dn_score, result.score(1,1,2), 'DN score mismatch');
assertElementsAlmostEqual(ref.score, result.score(1,1,3), 'WTCS score mismatch');

end

function testExtTagQueryCS(td)
%% External query with tags, CS, full row_space
% HDAC Glaser query -> trichostatin-A connection

up = parse_geneset(td.uptag);
dn = parse_geneset(td.dntag);
tagidx = find(strcmp('HDAC_UP', {up.head}));

% expected results
ref = struct('score', single(0.5551),...
             'up_score', single(0.5516),...
             'dn_score', single(-0.5585));
         
cid = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};

[qo, result] = sig_query_tool('build_id', 'a2', 'metric','cs',...
                'row_space', 'full', 'uptag',up(tagidx),'dntag',dn(tagidx),...
                'cid', cid, 'save_analysis', false);

assertEqual('cs', result.metric);            
assertElementsAlmostEqual(ref.up_score, result.score(1,1,1), 'UP score mismatch');
assertElementsAlmostEqual(ref.dn_score, result.score(1,1,2), 'DN score mismatch');
assertElementsAlmostEqual(ref.score, result.score(1,1,3), 'CS score mismatch');

end

function testIntQuerySpearmanLM(td)
%% Internal query, spearman, lm row_space

% expected results
ref = struct('score', single(0.6675));

sig_id = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};
cid = {'CPC006_MCF7_24H:BRD-A19037878:10'};
[qo, result] = sig_query_tool('build_id', 'a2', 'metric', 'spearman',...
                'row_space', 'lm', 'sig_id', sig_id,...
                'cid', cid, 'save_analysis', false);

assertEqual('spearman', result.metric);            
assertElementsAlmostEqual(ref.score, result.score(1,1,1), 'score mismatch');
end


function testIntQueryPearsonLM(td)
%% Internal query, pearson, lm row_space

% expected results
ref = struct('score', single(0.6740));

sig_id = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};
cid = {'CPC006_MCF7_24H:BRD-A19037878:10'};
[qo, result] = sig_query_tool('build_id', 'a2', 'metric', 'pearson',...
                'row_space', 'lm', 'sig_id', sig_id,...
                'cid', cid, 'save_analysis', false);

assertEqual('pearson', result.metric);            
assertElementsAlmostEqual(ref.score, result.score(1,1,1), 'score mismatch');
end

function testIntQueryPearsonLMStruct(td)
%% Internal query, pearson, lm row_space using matlab structures

% expected results
ref = struct('score', single(0.6740));

sig_id = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};
cid = {'CPC006_MCF7_24H:BRD-A19037878:10'};
score_file = '/cmap/data/build/a2y13q1/modzs_n369564x22268.gctx';
rid = parse_grp('/cmap/data/vdb/spaces/lm_epsilon_n978.grp');

score = parse_gctx(score_file, 'cid', cid, 'rid', rid);
sig_score = parse_gctx(score_file, 'cid', sig_id, 'rid', rid);

[qo, result] = sig_query_tool('build_id', 'custom', 'metric', 'pearson',...
                'row_space', 'lm', 'score', score, 'sig_score', sig_score,...
                'save_analysis', false);

assertEqual('pearson', result.metric);            
assertElementsAlmostEqual(ref.score, result.score(1,1,1), 'score mismatch');
end

function testIntQueryDefault(td)
%% Internal query, with defaults spearman, lm row_space

% expected results
ref = struct('score', single(0.6675));

sig_id = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};
cid = {'CPC006_MCF7_24H:BRD-A19037878:10'};
[qo, result] = sig_query_tool('build_id', 'a2', 'sig_id', sig_id,...
                'cid', cid, 'save_analysis', false);

assertEqual('spearman', result.metric);          
assertElementsAlmostEqual(ref.score, result.score(1,1,1), 'score mismatch');
end

function testIntQuerySpearmanBing(td)
%% Internal query, spearman, bing row_space

% expected results
ref = struct('score', single(0.6724));

sig_id = {'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10'};
cid = {'CPC006_MCF7_24H:BRD-A19037878:10'};
[qo, result] = sig_query_tool('build_id', 'a2', 'metric', 'spearman',...
                'row_space', 'bing', 'sig_id', sig_id,...
                'cid', cid, 'save_analysis', false);
assertEqual('spearman', result.metric);            
assertElementsAlmostEqual(ref.score, result.score(1,1,1), 'score mismatch');
end
