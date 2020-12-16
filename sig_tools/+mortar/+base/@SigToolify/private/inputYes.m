function tf = inputYes(prompt)
reply = getInput(prompt, '');
tf = strcmpi(reply, 'y');
end