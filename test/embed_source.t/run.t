Non-embedded works.

  $ pyml_bindgen person_specs.txt person Person -r no_check > person.ml
  $ dune exec ./person_runner.exe 2> /dev/null
  Person -- name: Hagrid, age: 111

Embedded works.

  $ pyml_bindgen person_specs.txt person Person -r no_check --embed-python-source=person.py > person.ml

Run ocamlformat to make sure it doesn't mess up any formatting of the
embedded Python source code.

  $ ocamlformat --enable --inplace person.ml 

Change the name of the original python source to make sure we aren't
just picking that up.

  $ mv person.py person_py_txt

Check the generated source.

  $ cat person.ml
  let filter_opt l = List.filter_map Fun.id l
  
  let import_module () =
    let source =
      {pyml_bindgen_string_literal|class Person:
      def __init__(self, name, age):
          self.name = name
          self.age = age
  
      def __str__(self):
          return(f'Person -- name: {self.name}, age: {self.age}')
  |pyml_bindgen_string_literal}
    in
    let filename =
      {pyml_bindgen_string_literal|person.py|pyml_bindgen_string_literal}
    in
    let bytecode = Py.compile ~filename ~source `Exec in
    Py.Import.exec_code_module
      {pyml_bindgen_string_literal|person|pyml_bindgen_string_literal} bytecode
  
  type t = Pytypes.pyobject
  
  let of_pyobject pyo = pyo
  
  let to_pyobject x = x
  
  let __init__ ~name ~age () =
    let callable = Py.Module.get (import_module ()) "Person" in
    let kwargs =
      filter_opt
        [
          Some ("name", Py.String.of_string name); Some ("age", Py.Int.of_int age);
        ]
    in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
  let __str__ t () =
    let callable = Py.Object.find_attr_string t "__str__" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

And run it.

  $ dune exec ./person_runner.exe
  Person -- name: Hagrid, age: 111

Now try a module inside a package.

  $ pyml_bindgen person_specs.txt person2 Person -r no_check --embed-python-source=py/cool_package/person2.py > person2.ml
  $ ocamlformat --enable --inplace person2.ml 
  $ mv py/cool_package/person2.py py/cool_package/person2_py_txt
  $ cat person2.ml
  let filter_opt l = List.filter_map Fun.id l
  
  let import_module () =
    let source =
      {pyml_bindgen_string_literal|class Person:
      def __init__(self, name, age):
          self.name = name
          self.age = age
  
      def __str__(self):
          return(f'Person -- name: {self.name}, age: {self.age}')
  |pyml_bindgen_string_literal}
    in
    let filename =
      {pyml_bindgen_string_literal|py/cool_package/person2.py|pyml_bindgen_string_literal}
    in
    let bytecode = Py.compile ~filename ~source `Exec in
    Py.Import.exec_code_module
      {pyml_bindgen_string_literal|person2|pyml_bindgen_string_literal} bytecode
  
  type t = Pytypes.pyobject
  
  let of_pyobject pyo = pyo
  
  let to_pyobject x = x
  
  let __init__ ~name ~age () =
    let callable = Py.Module.get (import_module ()) "Person" in
    let kwargs =
      filter_opt
        [
          Some ("name", Py.String.of_string name); Some ("age", Py.Int.of_int age);
        ]
    in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
  let __str__ t () =
    let callable = Py.Object.find_attr_string t "__str__" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

Run it.

  $ dune exec ./person2_runner.exe
  Person -- name: Hagrid, age: 111

Finally, let's combine an embedded Python module with a non-embedded
one in the same OCaml module and see that it works.

Move it back so we can use it again.

  $ mv person_py_txt person.py

First the person module.  It will not be embedded.

  $ pyml_bindgen person_specs.txt person Person --caml-module Person -r no_check > lib.ml

Now the thing module.  It will be embedded.

  $ pyml_bindgen thing_specs.txt thing Thing --caml-module Thing -r no_check --embed-python-source=thing.py >> lib.ml
  $ ocamlformat --enable --inplace lib.ml 

Make sure we can't access the original thing python module.

  $ mv thing.py thing_py_txt

And run it.

  $ cat lib.ml
  module Person : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : name:string -> age:int -> unit -> t
  
    val __str__ : t -> unit -> string
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let import_module () = Py.Import.import_module "person"
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let __init__ ~name ~age () =
      let callable = Py.Module.get (import_module ()) "Person" in
      let kwargs =
        filter_opt
          [
            Some ("name", Py.String.of_string name);
            Some ("age", Py.Int.of_int age);
          ]
      in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let __str__ t () =
      let callable = Py.Object.find_attr_string t "__str__" in
      let kwargs = filter_opt [] in
      Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  
  module Thing : sig
    type t
  
    val of_pyobject : Pytypes.pyobject -> t
  
    val to_pyobject : t -> Pytypes.pyobject
  
    val __init__ : color:string -> unit -> t
  
    val __str__ : t -> unit -> string
  end = struct
    let filter_opt l = List.filter_map Fun.id l
  
    let import_module () =
      let source =
        {pyml_bindgen_string_literal|class Thing:
      """A thing is pretty basic.  It does have a color though!"""
  
      def __init__(self, color):
          """Just to see if {| any |} characters mess it up."""
          self.color = color
  
      def __str__(self):
          return(f'Thing -- color: {self.color}')
  |pyml_bindgen_string_literal}
      in
      let filename =
        {pyml_bindgen_string_literal|thing.py|pyml_bindgen_string_literal}
      in
      let bytecode = Py.compile ~filename ~source `Exec in
      Py.Import.exec_code_module
        {pyml_bindgen_string_literal|thing|pyml_bindgen_string_literal} bytecode
  
    type t = Pytypes.pyobject
  
    let of_pyobject pyo = pyo
  
    let to_pyobject x = x
  
    let __init__ ~color () =
      let callable = Py.Module.get (import_module ()) "Thing" in
      let kwargs = filter_opt [ Some ("color", Py.String.of_string color) ] in
      of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  
    let __str__ t () =
      let callable = Py.Object.find_attr_string t "__str__" in
      let kwargs = filter_opt [] in
      Py.String.to_string
      @@ Py.Callable.to_function_with_keywords callable [||] kwargs
  end
  $ dune exec ./person_thing_runner.exe
  Person -- name: Hagrid, age: 111
  Thing -- color: orange

Watch out...if your Python code uses the reserved string literal
syntax that pyml_bindgen uses, it will break.  However, we use
{pyml_bindgen_string_literal| blah |pyml_bindgen_string_literal} so it
is pretty unlikely that you will find that in your Python code :)

  $ pyml_bindgen thing_specs.txt thing Thing --caml-module Thing -r no_check --embed-python-source=bad_thing.py > bad_lib.ml
  $ dune build 2> err
  [1]
  $ grep 'This will break' err
  20 |         """This will break :) {pyml_bindgen_string_literal| any |pyml_bindgen_string_literal}."""
  $ grep Error err
  Error: Syntax error

Gives good error when the specified python file doesn't exist.

  $ pyml_bindgen thing_specs.txt thing Thing --caml-module Thing -r no_check --embed-python-source=where_am_i.py
  pyml_bindgen: option `--embed-python-source': no `where_am_i.py' file
  Usage: pyml_bindgen [OPTION]... SIGNATURES PY_MODULE PY_CLASS
  Try `pyml_bindgen --help' for more information.
  [1]
