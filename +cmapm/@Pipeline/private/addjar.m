function addjar(jarlist, jarpath)
% ADDJAR Add Java archives to the class path.
if ischar(jarlist)
    jarlist = {jarlist};
end
jcp = javaclasspath;
for ii=1:length(jarlist)
    thisjar = fullfile(jarpath, jarlist{ii});
    if ~any(strcmp(thisjar, jcp))
        fprintf('Adding %s classpath\n', thisjar);
        javaaddpath(thisjar)
    end
end
end