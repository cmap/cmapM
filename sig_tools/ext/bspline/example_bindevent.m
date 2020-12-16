function example_bindevent
% Illustrates how to bind multiple events to a single event hook.

% Copyright 2010 Levente Hunyadi

fig = figure;
button = uicontrol(fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.2 0.2], ...
    'String', 'Click me');
gui_bind_event(button, 'Callback', {@example_bindevent_disp, 'This is a sample text'});
gui_bind_event(button, 'Callback', @example_bindevent_font);

button = uicontrol(fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0.2 0 0.2 0.2], ...
    'String', 'Click me');
gui_bind_event(button, 'Callback', @example_bindevent_font);

function example_bindevent_disp(obj, event, text)

disp(text);

function example_bindevent_font(obj, event)

switch get(obj, 'FontWeight')
    case 'light'
        set(obj, 'FontWeight', 'demi');
    case 'normal'
        set(obj, 'FontWeight', 'bold');
    case 'demi'
        set(obj, 'FontWeight', 'light');
    case 'bold'
        set(obj, 'FontWeight', 'normal');
end
