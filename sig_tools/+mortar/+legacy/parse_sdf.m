function sdf = parse_sdf(fname)

fid = fopen(fname,'r'); 
c = textscan(fid,repmat('%s',[1,9]),'Delimiter','\t','Headerlines',1) ; 
fclose(fid); 

sdf = struct('instance_id',[],'drug_name',[],'cell_line',[],'dose',[],'batch',[],...
    'drug_class',[],'ins_cell_fname',[],'veh_cell_fname',[],'type',[]); 

instance_id = c{1}; 
drug_name = c{2}; 
cell_line = c{3}; 
dose = c{4}; 
batch = c{5}; 
drug_class = c{6}; 
ins_cell_fname = c{7} ; 
veh_cell_fname = c{8}; 
types = c{9}; 

num_entries = length(c{1}); 
h = waitbar(0,'Parsing sdf file....'); 
for i = 1 : num_entries
    sdf(i).instance_id{1} = instance_id{i}; 
    sdf(i).drug_name{1} = drug_name{i}; 
    sdf(i).cell_line{1} = strtrim(cell_line{i}); 
    sdf(i).dose{1} = dose{i}; 
    sdf(i).batch{1} = batch{i}; 
    sdf(i).drug_class{1} = drug_class{i}; 
    sdf(i).ins_cell_fname{1} = strtrim(ins_cell_fname{i}); 
    if any(veh_cell_fname{i}==',')
        ix = find(veh_cell_fname{i}==','); 
        tmp = veh_cell_fname{i}; 
        sdf(i).veh_cell_fname = cell(length(ix)+1,1); 
        sdf(i).veh_cell_fname{1} = strtrim(tmp(2:ix(1)-1)); 
        if length(ix) == 2
            sdf(i).veh_cell_fname{2} = strtrim(tmp(ix(1)+1:ix(2)-1)); 
        else
            for j = 2 : length(ix) 
                sdf(i).veh_cell_fname{j} = strtrim(tmp(ix(j-1)+1:ix(j)-1)); 
            end
        end
        sdf(i).veh_cell_fname{end} = strtrim(tmp(ix(end)+1:(end-1))); 
    else
        sdf(i).veh_cell_fname{1} = strtrim(veh_cell_fname{i}); 
    end
    sdf(i).type{1} = types{i}; 
    waitbar(i/num_entries,h); 
end
close(h); 