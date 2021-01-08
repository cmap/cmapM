function fixed = rm_filedim(s)

fixed = regexprep(s, '_n$|_n[0-9]*x[0-9]*$','');

end