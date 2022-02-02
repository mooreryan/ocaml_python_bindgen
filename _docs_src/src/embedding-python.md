# Embedding Python Source Code

If you import modules in Python code, Python needs to be able to actually find these modules.

One way is to "install" the Python module you want with say, pip.  E.g., `pip install whatever`.

If you're working on a Python module along with your OCaml code, you probably don't want to do this.  Rather, you probably want to set the `PYTHONPATH` environment variable to the location of your Python modules.  (You can find an example an detailed explanation of that in the [importing modules](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/importing_modules) example on GitHub.)

The third option is to embed the Python code directly into the generated OCaml module.  The `--embed-python-source` CLI option lets you do this.  Basically, you just provide the path to the Python module you want to embed to that option, and it will all work out for you.  This way you don't have to have your user's worry about setting the `PYTHONPATH` properly.

To see it in action, check out the [example](https://github.com/mooreryan/ocaml_python_bindgen/tree/main/examples/embedding_python_source) on GitHub.


