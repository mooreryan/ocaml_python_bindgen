open! Base
open Cmdliner

let version = "0.1.3-alpha"

type opts = {
  signatures : string;
  py_module : string;
  py_class : string;
  caml_module : string option;
  of_pyo_ret_type : [ `No_check | `Option | `Or_error ];
  associated_with : [ `Class | `Module ];
  embed_python_source : string option;
}

let make_opts signatures py_module py_class caml_module of_pyo_ret_type
    associated_with embed_python_source =
  {
    signatures;
    py_module;
    py_class;
    caml_module;
    of_pyo_ret_type;
    associated_with;
    embed_python_source;
  }

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

(* See for info about how the enum works.
   https://github.com/dbuenzli/logs/blob/master/src/logs_cli.ml *)
let of_pyo_ret_type_term =
  let enum =
    [ ("no_check", `No_check); ("option", `Option); ("or_error", `Or_error) ]
  in
  let argv_conv = Arg.enum enum in
  let enum_alts = Arg.doc_alts_enum enum in
  let doc =
    Printf.sprintf
      "Return type of the of_pyobject function.  $(docv) must be %s." enum_alts
  in
  Arg.(
    value
    & opt argv_conv `Option
    & info [ "r"; "of-pyo-ret-type" ] ~doc ~docv:"OF_PYO_RET_TYPE")

let associated_with_term =
  let enum = [ ("class", `Class); ("module", `Module) ] in
  let argv_conv = Arg.enum enum in
  let enum_alts = Arg.doc_alts_enum enum in
  let doc =
    Printf.sprintf
      "Are the Python functions associated with a class or just a module?  \
       $(docv) must be %s."
      enum_alts
  in
  Arg.(
    value
    & opt argv_conv `Class
    & info [ "a"; "associated-with" ] ~doc ~docv:"ASSOCIATED_WITH")

let embed_python_source_term =
  let doc =
    "Use this option to embed Python source code directly in the OCaml \
     binary.  In this way, you won't have to ensure the Python interpreter can \
     find the module at runtime."
  in
  Arg.(
    value
    & opt (some non_dir_file) None
    & info [ "e"; "embed-python-source" ] ~docv:"PYTHON_SOURCE" ~doc)

let term =
  Term.(
    const make_opts $ signatures_term $ py_module_term $ py_class_term
    $ caml_module_term $ of_pyo_ret_type_term $ associated_with_term
    $ embed_python_source_term)

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
