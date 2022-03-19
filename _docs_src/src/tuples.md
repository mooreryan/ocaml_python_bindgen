# Handling Tuples

As of version 0.3.0, you can handle certain types of tuples directly.

- You can now bind tuples with 2, 3, 4, or 5 elements.
  - They can be passed in as arguments, or returned from functions.
  - Only basic types and Python objects are allowed in tuples.
  - You can also put tuples inside of collections, e.g., `(int * string) list`, but not Options or Or_errors.

If you need something more complicated then that, you will have to use some of the same tricks I talk about in the [dictionaries](dictionaries.md) or [dictionaries-2](dictionaries-2.md) help pages.

## Examples

You can find examples of binding tuples [here](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/tuples).
