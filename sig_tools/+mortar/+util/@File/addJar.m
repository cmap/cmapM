function addJar(jarlist, jarpath, isverbose)
% ADDJAR Add Java archives to the class path.
if ischar(jarlist)
    jarlist = {jarlist};
end
jcp = javaclasspath('-dynamic');
for ii=1:length(jarlist)
    thisjar = fullfile(jarpath, jarlist{ii});
    if ~any(strcmp(thisjar, jcp)) && ~any(strcmp(fullfile(pwd, thisjar), jcp))
        if isverbose
            fprintf(1, 'Adding %s to classpath', thisjar);
        end
        javaaddpath(thisjar)
    end
end
end