function tool_list = sigGenerateDocs()
    list_file = fullfile(mortarpath, 'toolchain/jenkins.prop');
    fid = fopen(list_file);
    tool_list = fgetl(fid);
    fclose(fid);
    
    tool_list = regexprep(tool_list, '^sig_tool_list=', '');
    tool_list = tokenize(tool_list, ',', '');
 
    footer = sprintf('\n</PRE>\n</BODY>\n</HTML>');
    
    index_table = struct('SigTool', '', 'Description', '', 'url', '');
    
    for i=1:length(tool_list)
        docfile = fullfile(mortarpath, 'tools/documentation', [tool_list{i} '.html']);
        helptext = evalc([tool_list{i} ' -h']);        
        SigName = regexp(helptext, '\w+(?= \[--help, -h\])', 'match');
        desc = regexp(helptext, '(?<=: ).*(?=\n\nSynopsis:)', 'match');
        
        if (isempty(SigName))
            continue
        end
        
        header = sprintf('<HTML>\n<HEAD>\n<TITLE>%s</TITLE>\n</HEAD>\n<BODY>\n<PRE>\n', ...
        SigName{1});
        
        page_text = [header, helptext, footer];
        
        fid = fopen(docfile, 'wt');
        fprintf(fid, '%s\n', page_text);
        fclose( fid);
        
        index_table(i,1).SigTool = SigName{1};
        index_table(i,1).Description = desc{1};
        index_table(i,1).url = fullfile('documentation', [tool_list{i} '.html']);
    end
    
    mk_html_table(fullfile(mortarpath, 'tools/SigToolCatalog.html'), index_table);
end