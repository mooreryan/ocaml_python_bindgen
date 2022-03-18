# Tuples

- They can be passed in as arguments, or returned from functions.
- Only basic types can occur in tuples
  - No nesting
  - No options
- You _can_ stick tuples inside a `List`, `Seq`, or `Array`, e.g., `(int * string) list`.
- If you break these rules, you will get runtime errors :)

## Generate bindings

See the `dune` file for auto-generating the bindings. If you don't want to use Dune rules for this, you can still use the rule as an example of how to run `pyml_bindgen` manually.
