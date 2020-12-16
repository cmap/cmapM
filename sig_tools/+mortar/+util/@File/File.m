classdef File
    
    methods (Static=true)
        
	% ADDJAR Add Java archives to the class path.        
	addJar(jarlist, jarpath, isverbose);

    % URI_TYPE Type of URI (Uniform resource identifier)
    ut = URIType(URI);

    % Test if argument is a file or folder.
    tf = isfile(fname, ftype);

    % Return path to arguments file
    argpath = getArgPath(mfname, mfclass);
    
    % Create a tool workfolder
    wkdir = makeToolFolder(out_path, toolname, prefix, create_subdir);
    
    %URL encode string
    s = encodeURL(url);
    %URL decode string
    s = decodeURL(url);
    end
end