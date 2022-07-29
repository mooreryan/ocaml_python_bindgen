(lang dune 3.0)

(generate_opam_files true)

(cram enable)

(version 0.4.0-SNAPSHOT)

(maintainers "Ryan M. Moore")

(authors "Ryan M. Moore")

(homepage "https://github.com/mooreryan/ocaml_python_bindgen")

(source
 (github mooreryan/ocaml_python_bindgen))

(documentation "https://mooreryan.github.io/ocaml_python_bindgen/")

(bug_reports "https://github.com/mooreryan/ocaml_python_bindgen/issues")

(package
 (name pyml_bindgen-dev)
 (synopsis "Development package for pyml_bindgen")
 (allow_empty)
 (depends
  (ocaml
   (>= "4.14"))
  bisect_ppx
  (core
   (>= "v0.15"))
  (core_bench
   (>= "v0.15"))
  (core_unix
   (>= "v0.15"))
  (ocamlformat
   (and
    (>= "0.21")
    (< "0.22")))
  (ocaml-lsp-server
   (>= "1.13"))
  pyml))

(package
 (name pyml_bindgen)
 (synopsis "Generate pyml bindings from OCaml value specifications")
 (depends
  ; Runtime deps
  (angstrom
   (>= "0.15.0"))
  (base
   (>= "v0.12"))
  (cmdliner
   (>= "1.1.0"))
  (ppx_let
   (>= "v0.12"))
  (ppx_sexp_conv
   (>= "v0.12"))
  (ppx_string
   (>= "v0.12"))
  (re
   (>= "1.10.0"))
  (stdio
   (>= "v0.12"))
  (ocaml
   (>= "4.08.0"))
  ; Test-only deps
  (conf-python-3-dev
   (and
    (>= "1")
    :with-test))
  (base_quickcheck
   (and
    (>= "v0.12")
    :with-test))
  (ocamlformat
   (and
    (>= "0.21.0")
    (< "0.22.0")
    :with-test))
  (ppx_assert
   (and
    (>= "v0.12")
    :with-test))
  (ppx_inline_test
   (and
    (>= "v0.12")
    :with-test))
  (ppx_expect
   (and
    (>= "v0.12")
    :with-test))
  (pyml :with-test)
  (shexp
   (and
    (>= "v0.14")
    :with-test))))
