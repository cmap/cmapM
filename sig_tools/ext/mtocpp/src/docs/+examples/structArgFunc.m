function rv = structArgFunc(struct1, struct2)
  % A function with struct arguments
  %
  % When working with structs you can also specify the required and optional
  % fields. This feature is deprecated. It can be activated setting the flag
  % 'AUTO_ADD_FIELDS' to 'true' in the mtoc++ configuration file.
  %
  % A line beginning with the words "Required fields of", "optional fields of" or
  % "generated fields of" start a block for descriptions for fields used by the
  % parameters or generated for the return values.
  %
  % Required fields of struct1:
  %  test: Description for required field struct1.test
  %
  % Optional fields of struct2:
  %  test2: Description for optional field struct2.test2
  %
  % Generated fields of rv:
  %  RB: Description for generated field rv.RB
  %
  % fields of parameters that are used in the function body are added to the
  % required fileds list automatically, if they are not documentated yet.
  struct1.auto_added;

  struct2.auto_added;

  % fields of return values that are assigned somewhere in the function body are
  % also added automatically to the list of generated fields
  rv.auto_added  = 1;

function dummy = subFunction(a, b)
  % documentation of a subfunction

  nope;
