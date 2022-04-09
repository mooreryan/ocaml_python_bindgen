Errors

  $ combine_rec_modules
  combine_rec_modules: required argument FILE is missing
  Usage: combine_rec_modules [OPTION]… FILE…
  Try 'combine_rec_modules --help' for more information.
  [1]
  $ combine_rec_modules missing.ml
  ERROR -- File missing.ml does not exist
  [1]
  $ combine_rec_modules missing.ml missing2.ml
  ERROR -- These files do not exist: missing.ml, missing2.ml
  [1]

