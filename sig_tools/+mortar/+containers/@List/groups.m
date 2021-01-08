function [gp, gpidx, gpfreq] = groups(obj)

[gpidx, ~, gp] = grp2idx(obj.data_);
gpfreq = accumarray(gpidx, ones(size(gpidx)));

end