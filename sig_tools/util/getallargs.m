function arg = getallargs(varargin)

pnames = varargin(1:2:end);
d ={''};
dflts = d(ones(size(pnames)));
arg = parse_args(pnames, dflts, varargin{:});

end