open! Base

type file_perm = int [@@deriving of_sexp]

module Mkdir : sig
  val mkdir : ?perm:file_perm -> string -> unit

  val mkdir_p : ?perm:file_perm -> string -> unit
end = struct
  let atom x = Sexp.Atom x

  let list x = Sexp.List x

  let record l =
    list (List.map l ~f:(fun (name, value) -> list [ atom name; value ]))

  (* This wrapper improves the content of the Unix_error exception raised by the
     standard library (by including a sexp of the function arguments), and it
     optionally restarts syscalls on EINTR. *)
  let improve f make_arg_sexps =
    try f ()
    with Unix.Unix_error (e, s, _) ->
      let buf = Buffer.create 100 in
      let fmt = Caml.Format.formatter_of_buffer buf in
      Caml.Format.pp_set_margin fmt 10000;
      Sexp.pp_hum fmt (record (make_arg_sexps ()));
      Caml.Format.pp_print_flush fmt ();
      let arg_str = Buffer.contents buf in
      raise (Unix.Unix_error (e, s, arg_str))

  let dirname_r filename = ("dirname", atom filename)

  let file_perm_r perm = ("perm", atom (Printf.sprintf "0o%o" perm))

  let[@inline always] improve_mkdir mkdir dirname perm =
    improve
      (fun () -> mkdir dirname perm)
      (fun () -> [ dirname_r dirname; file_perm_r perm ])

  let mkdir = improve_mkdir Unix.mkdir

  let mkdir_idempotent dirname perm =
    match Unix.mkdir dirname perm with
    | () -> ()
    (* [mkdir] on MacOSX returns [EISDIR] instead of [EEXIST] if the directory
       already exists. *)
    | exception Unix.Unix_error ((EEXIST | EISDIR), _, _) -> ()

  let mkdir_idempotent = improve_mkdir mkdir_idempotent

  let rec mkdir_p dir perm =
    match mkdir_idempotent dir perm with
    | () -> ()
    | exception (Unix.Unix_error (ENOENT, _, _) as exn) ->
        let parent = Caml.Filename.dirname dir in
        if String.( = ) parent dir then raise exn
        else (
          mkdir_p parent perm;
          mkdir_idempotent dir perm)

  let mkdir ?(perm = 0o750) dir = mkdir dir perm

  let mkdir_p ?(perm = 0o750) dir = mkdir_p dir perm
end

include Mkdir

(* Apapted from JaneStreet Core_unix. Original license follows. *)
(* The MIT License

   Copyright (c) 2008--2022 Jane Street Group, LLC opensource@janestreet.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. *)
