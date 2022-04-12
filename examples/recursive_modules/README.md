# Recursive Modules

When writing bindings for Python libraries, you will need to bind cyclic Python classes, or, Python classes that reference each other. Here is an example.

```python
class Cat:
    # Cats have humans
    def __init__(self, name):
        self.name = name
        self.human = None

    def __str__(self):
        if self.human:
            human = self.human.name
        else:
            human = "none"

        return f'Cat -- name: {self.name}, human: {human}'

    def adopt_human(self, human):
        self.human = human

class Human:
    # Humans have cats
    def __init__(self, name):
        self.name = name
        self.cat = None

    def __str__(self):
        if self.cat:
            cat = self.cat.name
        else:
            cat = "none"

        return f'Human -- name: {self.name}, cat: {cat}'

    def adopt_cat(self, cat):
        self.cat = cat
```

You can see that the `Cat` and `Human` classes make reference to one another. This can be a problem when writing OCaml bindings.

One solution is to use [recursive modules](https://ocaml.org/manual/recursivemodules.html). Rather than run `pyml_bindgen` separately for each class we want to bind, and then manually [modify](https://mooreryan.github.io/ocaml_python_bindgen/recursive/) the results to make the modules recursive, this directory shows you how you can use the helper scripts `gen_multi` and `combine_rec_modules` to automate this task.

## `gen_multi`

`gen_multi` is a wrapper for running `pyml_bindgen` multiples times and combining it's output into a single file.

It takes a tab-separated file (TSV), where each line describes the command line options for running `pyml_bindgen` on a specific specs file.

Here is what the input file `cli_specs.tsv` looks like from this example.

| signatures           | py_module | py_class | associated_with | caml_module | split_caml_module | embed_python_source | of_pyo_ret_type |
|----------------------|-----------|----------|-----------------|-------------|-------------------|---------------------|-----------------|
| specs/human_spec.txt | human     | Human    | class           | Human       | NA                | ../py/human.py      | no_check        |
| specs/cat_spec.txt   | cat       | Cat      | class           | Cat         | NA                | ../py/cat.py        | no_check        |

The first row must be given in this exact order.  Each column is one of the command line options to `pyml_bindgen`.  You can put `NA` (or `na`, or blank) in cases in which you would not pass the flag/option to `pyml_bindgen`.

One potentially tricky thing is that the file paths will be with respect to the location in which the `gen_multi` program is run from, rather than the location of the `cli_specs.tsv` file.  If it is giving you trouble, you could use absolute paths instead.

## `combine_rec_modules`

This is a simple script that takes the output of say, `gen_multi` and turns all of the modules into recursive modules.

Something like this

```ocaml
module A : sig
...
end = struct
...
end

module B : sig
...
end = struct
...
end

module C : sig
...
end = struct
...
end
```

would become something like this:

```ocaml
module rec A : sig
...
end = struct
...
end

and B : sig
...
end = struct
...
end

and C : sig
...
end = struct
...
end
```

## Generating the modules

See `lib/dune` for an automatic way to do this.  But basically, it goes something like this:

```bash
$ gen_multi ./specs/cli_specs.tsv \
  | combine_rec_modules /dev/stdin \
  | ocamlformat --name a.ml - \
  > lib.ml
```
