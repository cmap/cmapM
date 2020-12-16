function mk_jenkins_prop(prop_file, prop)
% MK_JENKINS_PROP Create a Jenkins properties file

assert(isstruct(prop), 'prop should be a structure');
fn = fieldnames(prop);
nf = length(fn);
lines = cell(nf, 1);
for ii=1:nf
    lines{ii} = sprintf('%s=%s', fn{ii}, print_dlm_line(prop.(fn{ii}), 'dlm', ','));
end
mkgrp(prop_file, lines);
