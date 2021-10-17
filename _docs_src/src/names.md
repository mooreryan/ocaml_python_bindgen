# Function & Argument Names

You can't pick just any old name for your functions and arguments :)

The main thing to remember is in addition to being valid OCaml names, they must also be [valid python names](https://docs.python.org/3/reference/lexical_analysis.html#identifiers).  This is because we pass the function name and argument names "as-is" to Python.

In addition to that, there are a couple other things to keep in mind.

* Argument names that match any of the types mentioned [above](#allowed-types) are not allowed.
* Argument names that start with any of the types mentioned [above](#allowed-types) are not allowed.  (E.g., `val foo : t -> int_thing:string -> unit -> float` will fail.)
* Argument names that end with any of the above types are actually okay.  You probably shouldn't name them like this but it works.  Really, it's just an artifact of the parsing :) This will probably be fixed at some point....
* Function names and arguments can start with underscores (e.g., `__init__`) but they cannot be *all* underscores.  E.g., `val ____ : ...` will not parse.
