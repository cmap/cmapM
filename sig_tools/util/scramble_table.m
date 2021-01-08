function tbl = scramble_table(tbl)

fn = fieldnames(tbl);
nrec = length(tbl);
nf = length(fn);
for ii=1:nf
    this_field = {tbl.(fn{ii})}';
    new_field = this_field(randperm(nrec));
    tbl = setarrayfield(tbl, [], fn{ii}, new_field);    
end


end