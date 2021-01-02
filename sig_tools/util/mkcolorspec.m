function [spec,width] = mkcolorspec(num_lines)

colors = {'blue','green','red','cyan','magenta','yellow','black'};

% will give 14 unique combinations

if num_lines > 14
    
    spec = repmat(colors,[1,ceil(num_lines/7)]); 
    width = NaN; 
    
else

    if num_lines <= length(colors)
        width = ones(num_lines,1); 
        spec = colors(1:num_lines); 
    else
        spec = cell(num_lines,1); 
        width = ones(num_lines,1); 
        spec(1:length(colors)) = colors ; 
        spec(length(colors)+1:end) = colors(1:(num_lines-length(colors)));  
        width(length(colors)+1:end) = 2; 
    end
    
end