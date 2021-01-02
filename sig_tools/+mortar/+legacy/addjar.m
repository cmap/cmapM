function addjar(jarlist, jarpath, isverbose)
if ~isvarexist('isverbose')
    isverbose = true;
end
% ADDJAR Add Java archives to the class path.
if ischar(jarlist)
    jarlist = {jarlist};
end
jcp = javaclasspath;
for ii=1:length(jarlist)
    thisjar = fullfile(jarpath, jarlist{ii});
    if ~any(strcmp(thisjar, jcp)) && ~any(strcmp(fullfile(pwd,thisjar), jcp))
        dbg(isverbose, 'Adding %s to classpath', thisjar);
        javaaddpath(thisjar)
    end
end
end