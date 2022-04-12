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
