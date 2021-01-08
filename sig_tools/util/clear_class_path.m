function clear_class_path()
jcp = javaclasspath;
for ii=1:length(jcp);
    javarmpath(jcp{ii});
end
end