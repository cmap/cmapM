function printList_(obj)
sigTools = obj.list_;
nt = numel(sigTools);
for ii=1:nt
    dbg(1, '%d. %s', ii, sigTools{ii});
end
end