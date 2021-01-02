function reply = getInput(prompt, validator, varargin)
% GETINPUT Get Validated input
% REPLY = GETINPUT(PROMPT, @VALIDATOR) prompts
% for input, executes validator on response and returns the validated response.
% REPLY = GETINPUT(PROMPT, []) get input without validating. Returns raw
% reply
isvalid = false;
while ~isvalid
    reply = input(prompt, 's');
    if ~isempty(validator)
        try
            isvalid = validator(reply, varargin{:});
        catch e
            warning('\n%s\nTry again...',e.message);
        end
    else
        isvalid = true;
    end
end
end