function list = mktexlist(pathname,look_for)

if nargin == 0
    pathname = pwd ; 
    look_for = {'conCluster','compareClassification'};
elseif nargin == 1
    look_for = {'conCluster','compareClassification'};
end

if strcmp(look_for,'all')
    lookup = dir(fullfile(pathname,'*.pdf')); 
    list(1).name = 'all'; 
    for i = 1 : length(lookup)
        list.instance(i).location = {fullfile(...
            pathname,lookup(i).name)}; 
    end
    return
end
    
lookup = dir(pathname); 

dir_labels = cell(length(lookup),1); 
for i = 1 : length(dir_labels)
    if lookup(i).isdir
        if any(lookup(i).name == '.')
            dir_labels{i} = 'NaN'; 
            continue
        end
        ix = find(lookup(i).name == '_'); 
        if isempty(ix)
            dir_labels{i} = 'NaN'; 
        else
            dir_labels{i} = lookup(i).name(1:ix-1); 
        end
    else
        dir_labels{i} = 'NaN'; 
    end
end

% writepanel

list = struct('instance',''); 
for i = 1 : length(look_for)
    ix = find(strcmp(look_for{i},dir_labels)); 
    list(i).name = look_for{i}; 
%     list(i).locations = cell(length(ix),1); 
    for j = 1 : length(ix)
        files = dir(fullfile(pathname,lookup(ix(j)).name,'*.pdf')); 
        if ~isempty(files)
            for k = 1 : length(files)
                list(i).instance(j).locations{k} = fullfile(...
                    pathname,lookup(ix(j)).name,files(k).name); 
            end
        end
        start = length(files) + 1; 
        files = dir(fullfile(pathname,lookup(ix(j)).name,'*.png'));
        if ~isempty(files)
            for k = start : start + (length(files)-1)
                list(i).instance(j).locations{k} = fullfile(...
                    pathname,lookup(ix(j)).name,files(k-start + 1).name); 
            end
        end
        
    end
end
        
if any(strcmp('writepanel',look_for))
    
    files = dir(fullfile(pathname,'*.pdf')); 

    list(end+1).instance(1).locations = {''};
    for i = 1 : length(files)
        list(end).instance(i).locations = {fullfile(pathname,...
            files(i).name)}; 
    end
    list(end).name = 'writepanel'; 
end