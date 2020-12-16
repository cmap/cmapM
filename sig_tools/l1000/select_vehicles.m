function [veh_stats, veh_cid, nveh] = select_vehicles(plate, plate_path)
% select a subset of vehicles for a given list of plates in a brew cohort.

np = length(plate);
veh_file = cell(np, 1);
for ii=1:np
    [~, fp] = find_file(fullfile(plate_path, plate{ii}, 'vehicle', 'vehicle_stats.txt'));
    assert(~isempty(fp), 'vehicle_stats.txt not found for %s', plate{ii})
    veh_file{ii} = fp{1};
end
veh_stats = merge_table(veh_file);

[dp, dpidx] = getcls(veh_stats.det_plate);
veh_stats.pct_rank = str2double(veh_stats.pct_rank)*100;
nv = length(veh_stats.cid);
keep = false(nv, 1);
% vehicles per plate
nveh = zeros(np, 1);
for ii=1:np
    vidx = find(dpidx==ii);
    % percentile self ranks of vehicle signatures    
    [sr, sridx] = sort(veh_stats.pct_rank(vidx));
    nr = length(sr);
    
    % keep all vehicles that meet 10% cutoff
    pick = sr<=10;      
    npick = nnz(pick);
    
    if nr>=10 && npick < 8
        % more than 10 vehicles pick best 8
        pick(1:8) = true;        
    elseif nr>3 && npick<3         
        % pick best 3        
        pick(1:3) = true;
    elseif npick<3
        % keep all
        dbg(1, 'Insufficient vehicles, selecting all %s', nr);
        pick(:) = true;        
    end
    
    keep(vidx(sridx(pick))) = true;
    nveh(ii) = nnz(pick);
end
veh_stats.keep = keep;
veh_cid = veh_stats.cid(keep);

end