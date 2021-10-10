(lang dune 2.8)

(generate_opam_files true)

(cram enable)

(package
 (name pyml_bindgen)
 (version 0.1.0)
 (license "MIT")
 (maintainers "Ryan Moore")
 (authors "Ryan Moore")
 (homepage "https://github.com/mooreryan/pyml_bindgen")
 (source (github mooreryan/pyml_bindgen))
 (documentation "https://github.com/mooreryan/pyml_bindgen")
 (bug_reports "https://github.com/mooreryan/pyml_bindgen/issues")
 (synopsis "Generate pyml bindings from OCaml signatures")
 (depends
   ; Runtime deps
   angstrom
   base
   cmdliner
   little_logger
   re2
   stdio
   ocaml
   ppx_jane
  ; Test-only deps
  (core_kernel :with-test)
  (ppx_inline_test :with-test)
  (ppx_expect :with-test)
  ; Dev deps
  (bisect_ppx :dev)))
