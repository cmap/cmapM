function [pass, rpt] = validate_json(instance,schema)
    % Function takes in two JSON files, an object and a JSON schema
    % and checks if the JSON instance is valid against the given schema
    % outputs a T/F variable 'pass' and a report of any error messages
    % as a cell array
    %
    % Author: Anup Jonchhe (anup@broadinstitute.org)
    % Date Created: September 19, 2019
    % Date Modified: September 19, 2019


    %addjar('org.everit.json.schema-1.5.1.jar', fullfile(mortarpath, 'ext/jars/'))
    %addjar('json-20180130.jar', fullfile(mortarpath, 'ext/jars'))
    %loader = org.everit.json.schema.loader.SchemaLoader()
    % Java-7 jars
    addjar({'threetenbp-1.4.0.jar', 'json-schema-java7-1.4.1.1.jar', 'json-20180130.jar'}, fullfile(mortarpath, 'ext/jars'))

    %import org.everit.json.schema.*;
    %import org.json.*;
    %import org.json.JSONPointerException;
    
    fid = fopen(schema, 'r');
    schema_str = char(fread(fid)');
    fclose(fid);
        
    schema = org.json.JSONObject(schema_str);
    %schema.toString(4); 

    schema = org.everit.json.schema.loader.SchemaLoader.load(schema);

    
    %loading in instance
    if isstruct(instance)
        inst_str = savejson('', instance);
    elseif (exist(instance, 'file') == 2)
        fid = fopen(instance,'r');
        raw = fread(fid);
        inst_str = char(raw');
        fclose(fid);
    else
        assert(exist(instance, 'file') ~= 7, 'Instance cannot be a path, use parse_build to scan build directory');
        inst_str = instance;
    end
    
    inst = org.json.JSONObject(inst_str);
    
    rpt = {};
    pass = 1;
    try
        schema.validate(inst)
    catch e
        pass = 0;
       if(isa(e,'matlab.exception.JavaException'))
           err_java = e.ExceptionObject;
           exceptions = err_java.getAllMessages();
           rpt = cell(exceptions.size,1);
           for i=1:exceptions.size
               msg = exceptions.get(i-1); %java object is index 0
               rpt{i} = sprintf('%s', msg);
           end
       end
    end
    
end

