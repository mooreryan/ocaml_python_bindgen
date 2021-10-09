open! Base
open Cmdliner

let version = "0.1.0"

type opts = {
  signatures : string;
  py_module : string;
  py_class : string;
  caml_module : string option;
}

let make_opts signatures py_module py_class caml_module =
  { signatures; py_module; py_class; caml_module }

let signatures_term =
  let doc = "Path to signatures" in
  Arg.(
    required & pos 0 (some non_dir_file) None & info [] ~docv:"SIGNATURES" ~doc)

(* For now, both py module and py class are required. *)
let py_module_term =
  let doc = "Python module name" in
  Arg.(required & pos 1 (some string) None & info [] ~docv:"PY_MODULE" ~doc)

let py_class_term =
  let doc = "Python class name" in
  Arg.(required & pos 2 (some string) None & info [] ~docv:"PY_CLASS" ~doc)

let caml_module_term =
  let doc = "Write full module and signature" in
  Arg.(
    value
    & opt (some string) None
    & info [ "c"; "caml-module" ] ~doc ~docv:"CAML_MODULE")

let term =
  Term.(
    const make_opts $ signatures_term $ py_module_term $ py_class_term
    $ caml_module_term)

let info =
  let doc = "generate pyml bindings for a set of signatures" in
  let man =
    [
      `S Manpage.s_description;
      `P "Generate pyml bindings from OCaml signatures.";
      `S Manpage.s_bugs;
      `P
        "Please report any bugs or issues on GitHub. \
         (https://github.com/mooreryan/pyml_bindgen/issues)";
      `S Manpage.s_see_also;
      `P
        "For full documentation, please see the GitHub page. \
         (https://github.com/mooreryan/pyml_bindgen)";
      `S Manpage.s_authors;
      `P "Ryan M. Moore <https://orcid.org/0000-0003-3337-8184>";
    ]
  in
  Term.info "pyml_bindgen" ~version ~doc ~man

let program = (term, info)

let parse_cli () =
  match Term.eval program with
  | `Ok opts -> Ok opts
  | `Help | `Version -> Error 0
  | `Error _ -> Error 1
