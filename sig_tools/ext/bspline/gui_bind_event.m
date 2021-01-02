function gui_bind_event(obj, event, callback)
% Registers a callback on a handle graphics object.
% This method allows registering multiple callbacks on a single handle
% graphics event hook.
%
% Input arguments:
% obj:
%    a handle graphics object
% event:
%    the name of the event for which to register the callback
% callback:
%    the callback to register, either as a function handle or as a cell
%    array

% Copyright 2010 Levente Hunyadi

validateattributes(obj, {'numeric'}, {'scalar'});
assert(ishandle(obj), 'gui_bind_event:ArgumentTypeMismatch', ...
    'Argument expected to be a valid handle graphics object.');
validateattributes(event, {'char'}, {'row'});

hook = get(obj, event);  % get already registered callbacks if any
if isempty(hook)  % no callbacks registered yet
    set(obj, event, { @gui_event ; callback });
elseif isa(hook, 'function_handle')  % a single function handle is registered
    set(obj, event, { @gui_event ; hook ; callback });  % append function handle passed as argument to list of callbacks
elseif iscell(hook)
    if isempty(hook)
        set(obj, event, { @gui_event ; callback });
    elseif iscellstr(hook)
        error('gui_bind_event:CellStringCallback', ...
            'Using the not recommended syntax of specifying a callback function with a cell array of strings is not supported.');
    elseif isa(hook{1}, 'function_handle') && strcmp('gui_event', func2str(hook{1}))
        set(obj, event, [ {@gui_event} ; hook(2:end) ; {callback} ]);
    else
        set(obj, event, { @gui_event ; hook ; callback });
    end
end

function gui_event(obj, event, varargin)
% Invokes all registered callbacks on an object event hook.
%
% Input arguments:
% obj:
%    a handle graphics object
% event:
%    the event structure passed to the handle graphics object
% callbacks:
%    a cell array of function handle callbacks registered on the object

for k = 1 : numel(varargin)
    callback = varargin{k};
    if isa(callback, 'function_handle')
        callback(obj, event);
    elseif iscell(callback)
        func = callback{1};
        args = callback(2:end);
        func(obj, event, args{:});
    end
end