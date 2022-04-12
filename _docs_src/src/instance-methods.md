# Instance Methods

Value specs for instance methods look like this:

```ocaml
val f : t -> a:'a -> ?b:'b -> ... -> unit -> 'c
```

## Rules

* The first argument must be `t`.
* The final function argument (penultimate type expression) must be `unit`.
* The return type can be any of the [types](./types.md) mentioned earlier.
* The remaining function arguments must either be named or optional.  The types of these arguments can be any of the types mentioned earlier.

Note on the final unit argument...I require all arguments that bind to Python method arguments be named or optional.  Python will often have optional named arguments at the end of a function's arguments.  In OCaml, these can't be erased unless you have a unit argument that comes after.  So, to keep the APIs all looking similar, I decided that all instance and static methods would end in a final unit argument.  This may change in the future.
