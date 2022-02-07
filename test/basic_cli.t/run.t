No arguments.

  $ pyml_bindgen
  pyml_bindgen: required arguments SIGNATURES, PY_MODULE, PY_CLASS are missing
  Usage: pyml_bindgen [OPTION]... SIGNATURES PY_MODULE PY_CLASS
  Try `pyml_bindgen --help' for more information.
  [1]

Version screen

  $ pyml_bindgen --version
  0.3.0-SNAPSHOT

Help screen

  $ pyml_bindgen --help=plain
  NAME
         pyml_bindgen - generate pyml bindings for a set of signatures
  
  SYNOPSIS
         pyml_bindgen [OPTION]... SIGNATURES PY_MODULE PY_CLASS
  
  DESCRIPTION
         Generate pyml bindings from OCaml signatures.
  
  ARGUMENTS
         PY_CLASS (required)
             Python class name
  
         PY_MODULE (required)
             Python module name
  
         SIGNATURES (required)
             Path to signatures
  
  OPTIONS
         -a ASSOCIATED_WITH, --associated-with=ASSOCIATED_WITH (absent=class)
             Are the Python functions associated with a class or just a module?
             ASSOCIATED_WITH must be either `class' or `module'.
  
         -c CAML_MODULE, --caml-module=CAML_MODULE
             Write full module and signature
  
         -e PYTHON_SOURCE, --embed-python-source=PYTHON_SOURCE
             Use this option to embed Python source code directly in the OCaml
             binary. In this way, you won't have to ensure the Python
             interpreter can find the module at runtime.
  
         --help[=FMT] (default=auto)
             Show this help in format FMT. The value FMT must be one of `auto',
             `pager', `groff' or `plain'. With `auto', the format is `pager` or
             `plain' whenever the TERM env var is `dumb' or undefined.
  
         -r OF_PYO_RET_TYPE, --of-pyo-ret-type=OF_PYO_RET_TYPE (absent=option)
             Return type of the of_pyobject function. OF_PYO_RET_TYPE must be
             one of `no_check', `option' or `or_error'.
  
         --version
             Show version information.
  
  BUGS
         Please report any bugs or issues on GitHub.
         (https://github.com/mooreryan/pyml_bindgen/issues)
  
  SEE ALSO
         For full documentation, please see the GitHub page.
         (https://github.com/mooreryan/pyml_bindgen)
  
  AUTHORS
         Ryan M. Moore <https://orcid.org/0000-0003-3337-8184>
  
File doesn't exist.

  $ pyml_bindgen apple pie good
  pyml_bindgen: SIGNATURES argument: no `apple' file
  Usage: pyml_bindgen [OPTION]... SIGNATURES PY_MODULE PY_CLASS
  Try `pyml_bindgen --help' for more information.
  [1]
