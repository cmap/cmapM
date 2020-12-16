function rpt = check_phenotype(pheno, min_class_sz)
% CHECK_PHENOTYPE Validate phenotype file
[cn, nl] = getcls({pheno.sig_id}');
nc = length(cn);

req_fn = {'sample_id', 'sig_id', 'class_id'};
[has_req_fn, is_fn] = has_required_fields(pheno, req_fn);
assert(has_req_fn, 'Required fields not found: %s', print_dlm_line(req_fn, ~is_fn));
rpt = struct('sig_id', cn,...
             'num_class', nan,...
             'class_a_size', nan,...
             'class_b_size', nan,...
             'passed_checks', true,...
             'status', 'PASS');
for ii=1:nc
    this = find(nl==ii);
    cl_tally = tally({pheno(this).class_id}', false);   
    num_class = length(cl_tally);
    passed_checks = true;
    status = 'PASS';
    has_min_class_size = all([cl_tally.group_size]'>=min_class_sz);
    if num_class>0
        class_a_size = cl_tally(1).group_size;
    else
        class_a_size = nan;
    end
    if num_class>1
        class_b_size = cl_tally(2).group_size;
    else
        class_b_size = nan;
    end

    % should have two classes
    if num_class ~=2
        dbg(1, '%s has one class', pheno(this(1)).sig_id);
        passed_checks = false;
        status = 'NOT_TWO_CLASS';
    end
    if ~has_min_class_size
        passed_checks = false;
        status = 'CLASS_TOO_SMALL';
    end
    rpt = setarrayfield(rpt, ii,...
                {'num_class', 'class_a_size', 'class_b_size',...
                'passed_checks', 'status'},...
                 num_class, class_a_size, class_b_size,...
                 passed_checks, status);
end
end