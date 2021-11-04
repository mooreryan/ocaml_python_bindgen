(lang dune 2.8)

(generate_opam_files true)

(cram enable)

(package
 (name pyml_bindgen)
 (version 0.1.2)
 (license "MIT")
 (maintainers "Ryan M. Moore")
 (authors "Ryan M. Moore")
 (homepage "https://github.com/mooreryan/ocaml_python_bindgen")
 (source (github mooreryan/ocaml_python_bindgen))
 (documentation "https://mooreryan.github.io/ocaml_python_bindgen/")
 (bug_reports "https://github.com/mooreryan/ocaml_python_bindgen/issues")
 (synopsis "Generate pyml bindings from OCaml value specifications")
 (depends
   ; Runtime deps
  (angstrom (>= "0.15.0"))
  (base (>= "v0.12"))
  (cmdliner (>= "1.0"))
  (ppx_let (>= "v0.12"))
  (ppx_sexp_conv (>= "v0.12"))
  (ppx_string (>= "v0.12"))
  (re2 (>= "v0.12"))
  (stdio (>= "v0.12"))
  (ocaml (>= "4.08.0"))
  ; Test-only deps
  (conf-python-3-dev (and (>= "1") :with-test))
  (core_kernel (and (>= "v0.12") :with-test))
  (ocamlformat :with-test)
  (ppx_inline_test (and (>= "v0.12") :with-test))
  (ppx_expect (and (>= "v0.12") :with-test))
  (pyml :with-test)
  ; Dev deps
  (bisect_ppx :dev)))