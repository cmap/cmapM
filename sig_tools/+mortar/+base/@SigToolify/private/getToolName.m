function tool_name = getToolName(class_name)
     tool_name = sprintf('sig_%s_tool',...
                    lower(strrep(class_name,'Sig','')));
end
