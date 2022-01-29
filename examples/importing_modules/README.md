# Importing Modules

Importing modules in Python can get a little weird.  In this example, I will show you how to successfully import Python modules that live in a subdirectory of your source directory.

## Directory structure

Here is the structure of this directory.

```
$ tree
.
├── dune
├── lib
│   ├── dune
│   ├── magic_dust.ml
│   ├── silly_math.ml
│   └── specs
│       ├── magic_dust
│       │   ├── hearts.txt
│       │   └── sparkles.txt
│       └── silly_math
│           ├── adder
│           │   └── add.txt
│           └── subtracter
│               └── subtract.txt
├── py
│   ├── magic_dust
│   │   ├── hearts.py
│   │   └── sparkles.py
│   └── silly_math
│       ├── adder
│       │   └── add.py
│       └── subtracter
│           └── subtract.py
├── README.md
├── run.ml
└── test
    ├── dune
    └── run.t
```

Let's talk about it.

## The `lib` directory

`lib` is the directory for OCaml library code for our little project.  The interesting thing is the `specs` directory.  In it, we have all of our value specifications `pyml_bindgen` needs to generate the `pyml` bindings.  I decided to organize that folder to match the structure of the Python "packages" that we will be binding.  You don't have to do that though, you can just dump them all in one folder if you want.

## The `py` directory

`py` is the directory of Python modules/packages that we want to bind.  Let's pretend that `magic_dust` and `silly_math` are two Python packages that we are developing along with this OCaml project.  Because they evolve in lock-step with the OCaml wrapper code, we don't have them installed in the normal Python way, rather, they live in this same repository.  Because they aren't "installed" system-wide, we will need to be a little careful so that our OCaml code can find the modules.

There are a couple of ways we could do this, but the nicest way I think is to make use of the `PYTHONPATH` environmental variable.  You can add directory paths (and other stuff) to that variable to tell Python where to find modules and packages.

One other thing to note, the `silly_math` module has sort of a silly structure, but that's just for learning purposes to show you that your file structure or module structure can be a little wonky and it will work out okay.

## Using these modules from Python

Pretend for a second we are writing a Python script, `my_cool_script.py`, that lives in this directory.

```python
import magic_dust.hearts
import magic_dust.sparkles
import silly_math.adder.add
import silly_math.subtracter.subtract

# Do some fun stuff with your modules!
```

Then you could run the script like so...

```
$ PYTHONPATH=./py python my_cool_script.py
```

And it will be able to find the modules.  But say you move that script to your `~/Desktop` for some reason.  Now, from your Desktop, you could run it like this (assuming that I cloned the `pyml_bindegn` repository in `$HOME/software/pyml_bindgen`.):

```
$ PYTHONPATH=$HOME/software/pyml_bindgen/examples/importing_modules/py python my_cool_script.py
```

See how we needed to adjust the Python path?  Now, if you are planning to use these Python modules a lot, you should probably update the `PYTHONPATH` in your shell config scripts (e.g., `.profile`, `.bashrc`, whatever).  Then you won't need to specify the `PYTHONPATH` on the command line each time you run the code.

## Generating bindings

Okay, so we will use this same idea in the code that we bind and run from OCaml.

One of the `pyml_bindgen` arguments is the name of the Python module from which the functions you are binding come.  In this example, there are four:

* `magic_dust.hearts`
* `magic_dust.sparkles`
* `silly_math.adder.add`
* `silly_math.subtracter.subtract`

So we can put those names for that `pyml_bindgen` argument.  First, we bind the `magic_dust` module.

```
pyml_bindgen lib/specs/magic_dust/hearts.txt magic_dust.hearts NA \
  --caml-module Hearts \
  --associated-with module \
  > lib/magic_dust.ml

pyml_bindgen lib/specs/magic_dust/sparkles.txt magic_dust.sparkles NA \
  --caml-module Sparkles \
  --associated-with module \
  >> lib/magic_dust.ml

ocamlformat lib/magic_dust.ml --inplace
```

This will create an OCaml module `Magic_dust` with two submodules, `Hearts` and `Sparkles`.

Next, the `silly_math` module.

```
pyml_bindgen lib/specs/silly_math/adder/add.txt silly_math.adder.add NA \
  --caml-module Add \
  --associated-with module \
  > lib/silly_math.ml

pyml_bindgen lib/specs/silly_math/subtracter/subtract.txt silly_math.subtracter.subtract NA \
  --caml-module Subtract \
  --associated-with module \
  >> lib/silly_math.ml

ocamlformat lib/silly_math.ml --inplace
```

This will create an OCaml module `Silly_math` with two submodules, `Add` and `Subtract`.  Notice that I changed the structure of the OCaml code as compared to the Python code, but that's okay.

In this project, our "main" executable will be `run.exe` once we build the project.  Let's see how to run it with `dune` by setting the `PYTHONPATH`.

```
$ PYTHONPATH=./py dune exec ./run.exe
```

If all goes well, you should see nothing printed, as that `run.exe` just runs some assertions.

## Running our program from anywhere

Let's say that we have installed `run.exe` somewhere on our computer and now we want to be able to run it from any directory.  In this case, you should update your `PYTHONPATH` in your shell config.  Something like this for example.

```
PYTHONPATH="${HOME}/software/pyml_bindgen/examples/importing_modules/py:${PYTHONPATH}"
```

Then you will be able to run the program from wherever like so:

```
# We are in the home directory now!
$ pwd
/home/ryan

# You may have more in here!
$ echo $PYTHONPATH
/home/ryan/software/pyml_bindgen/examples/importing_modules/py

# The PYTHONPATH is all good!
$ run.exe
```

## Automating binding generation

Running `pyml_bindgen` by hand isn't always the most fun.  You can have Dune automatically update the bindings for you whenever the specs files change using Dune's [rules](https://dune.readthedocs.io/en/stable/dune-files.html#rule).  The `dune` file in the `lib` directory has rules for auto-generating the OCaml modules.  The cool thing is that if you update one of the specs files, Dune will automatically pick up the change and regenerate the OCaml files...nice!
