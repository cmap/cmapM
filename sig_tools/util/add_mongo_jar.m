function add_mongo_jar(isverbose)
% ADD_MONGO_JAR Add the Java driver for MongoDB
if ~isvarexist('isverbose')
    isverbose = true;
end
% Jar files for Apache Velocity
jarlist ={'mongo.jar'};
jarpath = fullfile(mortarpath, 'ext/jars');
addjar(jarlist, jarpath, isverbose);
end