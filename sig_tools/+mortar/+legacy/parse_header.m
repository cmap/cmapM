function header = parse_header(fname)

fid = fopen(fname,'r'); 

hd = fgetl(fid); 
flag = zeros(1,length(hd)); 
for i = 1 : length(flag)
    if isspace(hd(i))
        flag(i) = 1 ; 
    end
end
ix = find(flag); 
header = cell(sum(flag)+1,1); 
header{1} = hd(1:ix(1)-1) ; 
for i = 1 : length(header) - 2
    header{i+1} = hd(ix(i)+1:ix(i+1)-1); 
end
header{end} = hd(ix(end)+1:end); 
fclose(fid); 