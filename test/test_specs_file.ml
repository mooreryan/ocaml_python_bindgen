open! Core_kernel
open! Lib

let with_data_as_file ~data ~f =
  let fname, oc = Caml.Filename.open_temp_file "pyml_bindeng_test" "" in
  Exn.protectx
    ~f:(fun oc ->
      Out_channel.output_string oc data;
      Out_channel.flush oc;
      f ~file_name:fname)
    ~finally:Out_channel.close oc

let test_data =
  {|val add : x:int -> y:int ->
  unit -> int

# ..........
# ................

# @py_fun_name=add
val add_int : x:int ->
  y:int ->
  unit -> int
[@@py_fun_name add]


# I like cheese.
#
#And#Apples
#Pie
#
# @py_fun_name=add
val add_float :
  x:float -> y:float -> unit -> float
[@@py_fun_name           add]


val sub : x:int -> y:int -> unit -> int
[@@py_fun_name silly]
  [@@yummy cake_stuff]
[@@thing what]

# Comment at the end

# HEHE
|}

let%expect_test _ =
  let specs =
    with_data_as_file ~data:test_data ~f:(fun ~file_name ->
        Specs_file.read file_name)
  in
  print_s @@ [%sexp_of: Specs_file.spec list] specs;
  [%expect
    {|
    (((attrs ()) (val_spec "val add : x:int -> y:int -> unit -> int"))
     ((attrs ("[@@py_fun_name add]"))
      (val_spec "val add_int : x:int -> y:int -> unit -> int"))
     ((attrs ("[@@py_fun_name           add]"))
      (val_spec "val add_float : x:float -> y:float -> unit -> float"))
     ((attrs ("[@@py_fun_name silly] [@@yummy cake_stuff] [@@thing what]"))
      (val_spec "val sub : x:int -> y:int -> unit -> int"))) |}]

let%expect_test "attributes must start a line" =
  let data = {| val f : int [@@apple pie] -> int |} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect {| (Error (Failure "attributes must start a line")) |}]

let%expect_test _ =
  let data = {|
int -> int
[@@apple pie]
[@@is good]
|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect
    {| (Error (Failure "In the middle of a val spec, but have none to work on.")) |}]

let%expect_test _ =
  let data = {|
[@@apple pie]
[@@is good]
|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect
    {| (Error (Failure "We have attributes but no val spec for them to go with.")) |}]

let%expect_test _ =
  let data = {|
val f : int
[@@apple pie]
int -> float
|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect
    {| (Error (Failure "Found unused attrs but in the middle of a val spec.")) |}]

let%expect_test _ =
  let data = {|
val f : int ->
float
|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect {| (Ok (((attrs ()) (val_spec "val f : int -> float")))) |}]

let%expect_test _ =
  let data = {|
val f : int ->
float
[@@hello world]|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect
    {| (Ok (((attrs ("[@@hello world]")) (val_spec "val f : int -> float")))) |}]

let%expect_test _ =
  let data = {|
val f : int -> float
[@@hello world]
|} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect {| (Ok (((attrs ("[@@hello world]")) (val_spec "val f : int -> float")))) |}]

let%expect_test _ =
  let data = {| val f : int -> float |} in
  let specs =
    with_data_as_file ~data ~f:(fun ~file_name ->
        Or_error.try_with (fun () -> Specs_file.read file_name))
  in
  print_s @@ [%sexp_of: Specs_file.spec list Or_error.t] specs;
  [%expect {| (Ok (((attrs ()) (val_spec "val f : int -> float")))) |}]
