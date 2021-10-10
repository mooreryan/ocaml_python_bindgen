Setup env

  $ export SANITIZE_LOGS=$PWD/../helpers/sanitize_logs

Basic usage.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  $ dune exec ./hi.exe 2> /dev/null
  all good!

Sigs with t no_check, but requesting or_error fail.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  F, [DATE TIME PID] FATAL -- You said you wanted Or_error return type, but Or_error was not found in the sigs.

Sigs with t option, but requesting or_error fail.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_option.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  F, [DATE TIME PID] FATAL -- You said you wanted Or_error return type, but Or_error was not found in the sigs.

Mixed return types will fail.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check_option.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml 2> err
  [1]
  $ bash "${SANITIZE_LOGS}" err
  F, [DATE TIME PID] FATAL -- You said you wanted Or_error return type, but Or_error was not found in the sigs.

If you have no_check or option mixed in with or error, and you request
or_error, pyml_bindgen will NOT fail.  But compiling the result, WILL
fail.

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_no_check_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  $ dune exec ./hi.exe 2> err
  [1]
  $ grep -i --silent 'signature mismatch' err

  $ if [ -f lib.ml ]; then rm lib.ml; fi
  $ pyml_bindgen silly_sigs_option_or_error.txt silly_mod Silly --caml-module=Silly --of-pyo-ret-type=or_error > lib.ml
  $ dune exec ./hi.exe 2> err
  [1]
  $ grep -i --silent 'signature mismatch' err
