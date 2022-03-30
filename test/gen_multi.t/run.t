Order of tsv file matters.

  $ gen_multi specs/cli_specs.tsv | grep '^module'
  module Human : sig
  module Cat : sig

  $ gen_multi specs/cli_specs_cat_first.tsv | grep '^module'
  module Cat : sig
  module Human : sig

Relative filenames will be relative to where the command is run, not where the
file is.

  $ gen_multi specs/bad/bad.tsv
  (Sys_error "../cat_spec.txt: No such file or directory")
  [1]

Errors

  $ gen_multi
  usage: gen_multi <specs.txt> > lib.ml
  [1]
  $ gen_multi fake_file
  ERROR -- File fake_file does not exist
  [1]
  $ gen_multi bad.tsv
  (Failure "bad config line: is good")
  [1]
