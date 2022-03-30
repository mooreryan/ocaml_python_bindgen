open! Base

(* TODO ideally we would integrate this parsing step with our other parsers and
   then have a single "specs file" parser. *)

type spec = { attrs : string option; val_spec : string } [@@deriving sexp]

let is_comment_line s = String.is_prefix ~prefix:"#" s

let is_val_start s = String.is_prefix ~prefix:"val" s

let all_whitespace = Re.compile @@ Re.Perl.re "^\\s*$"

let is_all_whitespace s = Re.execp all_whitespace s

let comment_marker = Re.compile @@ Re.Perl.re "^#\\s*"

let cat s1 s2 = s1 ^ " " ^ s2

(* TODO should we include 0-9 here? *)
(* TODO We are being more restrictive than normal in that each attr must be on
   its own line, and only one per line. *)
let attribute_line =
  Re.compile @@ Re.Perl.re "^\\s*\\[@@[a-zA-Z_]+\\s+[a-zA-Z_ ]+\\]\\s*$"

let attributes_not_at_start =
  Re.compile @@ Re.Perl.re "^\\S+.*\\[@@[a-zA-Z_]+\\s+[a-zA-Z_ ]+\\]"

let has_attributes_not_at_start line = Re.execp attributes_not_at_start line

let is_attribute_line line = Re.execp attribute_line line

(* assert false cases should be impossible unless I made a mistake. failwith
   cases can happen with bad user input in the file. *)
let read fname =
  let open Stdio in
  let lines =
    List.filter ~f:(fun l ->
        (not (is_all_whitespace l)) && not (is_comment_line l))
    @@ In_channel.read_lines fname
  in
  let current_attr, current_val_spec, specs =
    List.fold lines ~init:(None, None, [])
      ~f:(fun (attrs, val_spec, all) line ->
        let line = String.strip line in
        if has_attributes_not_at_start line then
          failwith "attributes must start a line";
        match (is_attribute_line line, is_val_start line, attrs, val_spec) with
        | true, true, None, None
        | true, true, None, Some _
        | true, true, Some _, None
        | true, true, Some _, Some _ ->
            assert false
        (* In an attribute line *)
        | true, false, None, None ->
            failwith "We have attributes but no val spec for them to go with."
        | true, false, Some _, None -> assert false
        | true, false, None, Some current_val_spec ->
            let new_attrs = line in
            (Some new_attrs, Some current_val_spec, all)
        | true, false, Some current_attrs, Some current_val_spec ->
            let new_attrs = line in
            (Some (cat current_attrs new_attrs), Some current_val_spec, all)
        (* Starting a new val spec *)
        | false, true, None, None ->
            let new_val_spec = line in
            (None, Some new_val_spec, all)
        | false, true, None, Some current_val_spec ->
            (* Track the old val spec. *)
            let all = { attrs = None; val_spec = current_val_spec } :: all in
            (* Set up the new one. *)
            let new_val_spec = line in
            (None, Some new_val_spec, all)
        | false, true, Some _, None -> assert false
        | false, true, Some current_attrs, Some current_val_spec ->
            (* Track the old val spec. *)
            let all =
              { attrs = Some current_attrs; val_spec = current_val_spec } :: all
            in
            (* Set up the new one. *)
            let new_val_spec = line in
            (None, Some new_val_spec, all)
        (* In the middle of a val spec *)
        | false, false, None, None ->
            failwith "In the middle of a val spec, but have none to work on."
        | false, false, None, Some current_val_spec ->
            let new_val_spec = line in
            (None, Some (cat current_val_spec new_val_spec), all)
        | false, false, Some _, None -> assert false
        | false, false, Some _, Some _ ->
            failwith "Found unused attrs but in the middle of a val spec.")
  in
  (* Finish off last spec if it is there. *)
  let specs =
    match (current_attr, current_val_spec) with
    | None, None -> specs
    | None, Some val_spec -> { attrs = None; val_spec } :: specs
    | Some _, None ->
        prerr_endline
          "WARNING: currently in a attributes line but hit EOF without getting \
           a val_spec to go with it.";
        specs
    | Some attrs, Some val_spec -> { attrs = Some attrs; val_spec } :: specs
  in
  List.rev specs
