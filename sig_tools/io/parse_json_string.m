function dbo = parse_json_string(s)
%import com.mongodb.util.JSON.parse
dbo = com.mongodb.util.JSON.parse(s);
end
