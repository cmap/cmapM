This is a Matlab extension supporting access to MongoDB.

After cloning this repo, copy the src directory from [mongo-c-driver](http://github.com/mongodb/mongo-c-driver)
to the main directory of this extension.  Alternately, you may unpack mongo-c-driver-src.zip into this directory.

Windows:

Binaries for 64 and 32-bit are provided.  Rename MongoMatlabDriver32.dll or MongoMatlabDriver64.dll to 
MongoMatlabDriver.dll as appropriate.

Building: Load the solution into Visual Studio and build the dll.  The project properties may need to be edited
to include the locations where the Matlab include files and libs are.


Linux:

`~/10gen/mongo-matlab-driver$ make`

Note that Matlab requires gcc-4.3

-----
Once the libary is built,

Add the path of the driver to Matlab:
`> addpath /10gen/mongo-matlab-driver`

Then the test suite can be run with:
`> MongoTest`
(after changing the current directory to that of this driver)

For normal operation, load the library with:
`> MongoStart`

Documentation may be accessed within Matlab by:
`> doc Mongo % for instance`

though you may find it more convenient to examine the class files directly.  Matlab clutters up the
help somewhat with documention on methods inherited from 'handle'.

Unload the library with:
`> MongoStop`

(you may have to clear variables in order to do this)


BASIC USAGE:

Connecting to a MongoDB server running on localhost is as straight forward and simple as:

`mongo = Mongo();`

This creates an instance of the Mongo class which you'll use for subsequent communication with MongoDB.
Once you have established the connection, you may execute CRUD operations on the database quite easily.
Simplified prototypes for these look like this:

`mongo.insert(namespace, record);`

`result = mongo.findOne(namespace, query);`

`mongo.update(namespace, criteria, objNew);`

`mongo.remove(namespace, criteria);`

namespace is the name of the collection on which to perform the operation.

A simple example of an actual insert looks like this:

`bb = BsonBuffer;`

`bb.append('name', 'John');`

`bb.append('age', int32(34));`

`bb.append('address', '1033 Vine Street');`

`record = bb.finish();`

`mongo.insert('test.people', record);`


There are 3 convenience functions for storing named values to the collection 'Matlab.vars'.
These are:
mongo.put('name', value)  to store a value with a given name.
value = mongo.get('name') to fetch the value associated with a name.
mongo.list();  to list the names of the values stored.

If you find these functions handy and useful, you may want to index 'Matlab.vars' by name:
mongo.indexCreate('Matlab.vars', 'name')

There is a sample Matlab script which you can run with:

`MongoSample`

This simple example demonstrates the most common operations of inserting, updating and 
also the 'usual' query / find loop.
