function javaclearpath()
% JAVACLEARPATH Clear dynamic java path

jcp = javaclasspath;
for ii=1:length(jcp)
    javarmpath(jcp{ii});
end
end