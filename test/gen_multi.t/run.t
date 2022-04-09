Order of tsv file matters.

  $ gen_multi specs/cli_specs.tsv | grep '^module'
  module Human : sig
  module Cat : sig

  $ gen_multi specs/cli_specs_cat_first.tsv | grep '^module'
  module Cat : sig
  module Human : sig
