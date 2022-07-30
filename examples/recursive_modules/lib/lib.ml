module rec Human : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t
  val to_pyobject : t -> Pytypes.pyobject
  val create : name:string -> unit -> t
  val to_string : t -> unit -> string
  val adopt_cat : t -> cat:Cat.t -> unit -> unit
  val name : t -> string
  val cat : t -> Cat.t
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let py_module =
    lazy
      (let source =
         {pyml_bindgen_string_literal|class Human:
    # Humans have cats
    def __init__(self, name):
        self.name = name
        self.cat = None

    def __str__(self):
        if self.cat:
            cat = self.cat.name
        else:
            cat = "none"

        return f'Human -- name: {self.name}, cat: {cat}'

    def adopt_cat(self, cat):
        self.cat = cat
|pyml_bindgen_string_literal}
       in
       let filename =
         {pyml_bindgen_string_literal|../py/human.py|pyml_bindgen_string_literal}
       in
       let bytecode = Py.compile ~filename ~source `Exec in
       Py.Import.exec_code_module
         {pyml_bindgen_string_literal|human|pyml_bindgen_string_literal}
         bytecode)

  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let of_pyobject pyo = pyo
  let to_pyobject x = x

  let create ~name () =
    let callable = Py.Module.get (import_module ()) "Human" in
    let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let to_string t () =
    let callable = Py.Object.find_attr_string t "__str__" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let adopt_cat t ~cat () =
    let callable = Py.Object.find_attr_string t "adopt_cat" in
    let kwargs = filter_opt [ Some ("cat", Cat.to_pyobject cat) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let name t = Py.String.to_string @@ Py.Object.find_attr_string t "name"
  let cat t = Cat.of_pyobject @@ Py.Object.find_attr_string t "cat"
end

and Cat : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t
  val to_pyobject : t -> Pytypes.pyobject
  val create : name:string -> unit -> t
  val to_string : t -> unit -> string
  val adopt_human : t -> human:Human.t -> unit -> unit
  val name : t -> string
  val human : t -> Human.t
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let py_module =
    lazy
      (let source =
         {pyml_bindgen_string_literal|class Cat:
    # Cats have humans
    def __init__(self, name):
        self.name = name
        self.human = None

    def __str__(self):
        if self.human:
            human = self.human.name
        else:
            human = "none"

        return f'Cat -- name: {self.name}, human: {human}'

    def adopt_human(self, human):
        self.human = human
|pyml_bindgen_string_literal}
       in
       let filename =
         {pyml_bindgen_string_literal|../py/cat.py|pyml_bindgen_string_literal}
       in
       let bytecode = Py.compile ~filename ~source `Exec in
       Py.Import.exec_code_module
         {pyml_bindgen_string_literal|cat|pyml_bindgen_string_literal} bytecode)

  let import_module () = Lazy.force py_module

  type t = Pytypes.pyobject

  let of_pyobject pyo = pyo
  let to_pyobject x = x

  let create ~name () =
    let callable = Py.Module.get (import_module ()) "Cat" in
    let kwargs = filter_opt [ Some ("name", Py.String.of_string name) ] in
    of_pyobject @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let to_string t () =
    let callable = Py.Object.find_attr_string t "__str__" in
    let kwargs = filter_opt [] in
    Py.String.to_string
    @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let adopt_human t ~human () =
    let callable = Py.Object.find_attr_string t "adopt_human" in
    let kwargs = filter_opt [ Some ("human", Human.to_pyobject human) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let name t = Py.String.to_string @@ Py.Object.find_attr_string t "name"
  let human t = Human.of_pyobject @@ Py.Object.find_attr_string t "human"
end
