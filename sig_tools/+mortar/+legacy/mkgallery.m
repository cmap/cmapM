function mkgallery(imlist, ofname, varargin)

pnames = {'caption', 'height', 'width', ...
    'ncol', 'title', 'thumbdir', ...
    'template_path', 'template'};
dflts = {{}, 450, 565,...
    2, '', '', ...
    fullfile(mortarpath, 'templates'), 'gallery.vm'};
args = parse_args(pnames, dflts, varargin{:});

% usethumb = ~isempty(args.thumbdir);
add_velocity_jar;

% Initialize Velocity
ve = org.apache.velocity.app.VelocityEngine();
ve.setProperty('file.resource.loader.path', args.template_path)
ve.init()
tpl = ve.getTemplate(args.template);

% Create a context and add data 
context = org.apache.velocity.VelocityContext();

context.put('imlist', imlist);
context.put('caption', args.caption);
% context.put('ncol', args.ncol);
% context.put('width', args.width);
% context.put('height', args.height);

% Passing a java hashmap is possible, read from velocity as $opt.ncol
% note the default is to use floats, if integers are required need to cast.
% eg. int32(val)
opt = hashmap({'ncol','width','height','title','thumbdir'}, ...
    {int32(args.ncol), args.width, args.height, args.title, args.thumbdir});
context.put('opt', opt);

% write to file
fileWriter = java.io.OutputStreamWriter(java.io.FileOutputStream(ofname));
tpl.merge(context, fileWriter);
fileWriter.close();

% import java.io.StringWriter
% now render the template into a StringWriter 
% writer = StringWriter();
% tpl.merge( context, writer );
% show the World 
% disp( writer.toString() );

end
