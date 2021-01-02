% STRIP_DIMLABEL remove dimension string from a label.
function s = strip_dimlabel(l)
s = regexprep(l, '_n[0-9]*x[0-9]*$','');