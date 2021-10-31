Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

Basic usage.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ dune exec ./hi.exe 2> /dev/null
  all good!

Sigs with t option, but requesting no check work, but give compiler
error if you try to run the code.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_option.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ dune exec ./hi.exe 2> err
  [1]
  $ grep -i --silent 'signature mismatch' err

Sigs with t Or_error.t, but requesting no check fail.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  ERROR: You said you wanted No_check return type, but Or_error was found in the sigs.

Mixed return types will give if you try to run the code.  pyml_bindgen
program will run fine however...

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check_option.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml
  $ dune exec ./hi.exe 2> err
  [1]
  $ grep -i --silent 'signature mismatch' err

If Or_error is present in the signatures but not passed correct
--of-pyo-ret-type, it's an error.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  ERROR: You said you wanted No_check return type, but Or_error was found in the sigs.


  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_option_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=no_check > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  ERROR: You said you wanted No_check return type, but Or_error was found in the sigs.
