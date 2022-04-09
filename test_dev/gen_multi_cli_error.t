Relative filenames will be relative to where the command is run, not where the
file is.

  $ gen_multi specs/bad/bad.tsv
  (Sys_error "../cat_spec.txt: No such file or directory")
  [1]

Errors

  $ gen_multi
  gen_multi: required argument CLI_OPTS is missing
  Usage: gen_multi [OPTION]… CLI_OPTS
  Try 'gen_multi --help' for more information.
  [1]
  $ gen_multi fake_file
  gen_multi: CLI_OPTS argument: no 'fake_file' file
  Usage: gen_multi [OPTION]… CLI_OPTS
  Try 'gen_multi --help' for more information.
  [1]
  $ gen_multi bad.tsv
  (Failure "bad config line: is good")
  [1]

It tells you about all the files that are bad.

  $ gen_multi specs/bad_file_names.tsv
  ((Sys_error "specs/human_spec.txttt: No such file or directory")
   (Sys_error "specs/cat_spec.txttt: No such file or directory"))
  [1]
