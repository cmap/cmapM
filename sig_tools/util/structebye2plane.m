% STRUCTPLANE2EBYE Convert the organization of a structure.
% Convert from plane to an element by element format.

function news = structebye2plane (s)

fn = fieldnames(s);

for ii=1:length(fn)
%     if iscell(s.(fn{ii}))
%         x=s.(fn{ii});
%     else
%         x = num2cell(s.(fn{ii}));
%     end
    news.(fn{ii}) = {s.(fn{ii})}';
%     [news(1:length(s.(fn{ii})),1).(fn{ii})] = x{:};
end
