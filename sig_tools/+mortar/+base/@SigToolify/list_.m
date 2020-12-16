function varargout = list_(obj, varargin)
mp = meta.package.fromName(obj.SigToolPackage);
sigTools = sort(strrep({mp.ClassList.Name}', strcat(obj.SigToolPackage,'.'), ''));
if ~nargout
    obj.printList_;
else
    varargout(1) = {sigTools};
end
end