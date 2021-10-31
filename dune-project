(lang dune 2.8)

(generate_opam_files true)

(cram enable)

(package
 (name pyml_bindgen)
 (version 0.1.0)
 (license "MIT")
 (maintainers "Ryan M. Moore")
 (authors "Ryan M. Moore")
 (homepage "https://github.com/mooreryan/pyml_bindgen")
 (source (github mooreryan/pyml_bindgen))
 (documentation "https://mooreryan.github.io/ocaml_python_bindgen/")
 (bug_reports "https://github.com/mooreryan/pyml_bindgen/issues")
 (synopsis "Generate pyml bindings from OCaml value specifications")
 (depends
   ; Runtime deps
   angstrom
   base
   cmdliner
   ppx_jane
   re2
   stdio
   ocaml
  ; Test-only deps
  (core_kernel :with-test)
  (ocamlformat :with-test)
  (ppx_inline_test :with-test)
  (ppx_expect :with-test)
  (pyml :with-test)
  ; Dev deps
  (bisect_ppx :dev)))
