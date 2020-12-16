function status = save(obj, fname)
% Save list to a text file
%   SAVE(FNAME) Saves the list to a newline delimited file FNAME 
%
%   See also: parse

fid = fopen(fname ,'wt');
for ii=1:length(obj.data_)
    switch(class(obj.data_{ii}))
        case 'char'
            fprintf(fid, '%s\n', obj.data_{ii});
        otherwise
            fprintf(fid, '%f\n', obj.data_{ii});            
    end
end
status = fclose(fid);
