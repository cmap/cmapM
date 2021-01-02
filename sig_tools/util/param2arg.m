function a = param2arg(p)

fn = fieldnames(p);
nfn=length(fn);
a = cell(2*nfn,1);
a(1:2:end) = fn;
for ii=1:nfn
    a(2*ii) = {p.(fn{ii})};
end

end