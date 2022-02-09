module Cat : sig
  type t

  val of_pyobject : Pytypes.pyobject -> t

  val to_pyobject : t -> Pytypes.pyobject

  val create : name:string -> unit -> t

  val to_string : t -> unit -> string

  val eat : t -> num_mice:int -> unit -> unit

  val eat_part : t -> num_mice:float -> unit -> unit

  val jump : t -> how_high:int -> unit -> unit

  val climb : t -> how_high:int -> unit -> unit
end = struct
  let filter_opt l = List.filter_map Fun.id l

  let py_module =
    lazy
      (let source =
         {pyml_bindgen_string_literal|class Cat:
    def __init__(self, name):
        self.name = name
        self.hunger = 0

    def __str__(self):
        return(f'Cat -- name: {self.name}, hunger: {self.hunger}')

    def eat(self, num_mice=1):
        self.hunger -= (num_mice * 5)
        if self.hunger < 0:
            self.hunger = 0

    def jump(self, how_high=1):
        if how_high > 0:
            self.hunger += how_high
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

  let eat t ~num_mice () =
    let callable = Py.Object.find_attr_string t "eat" in
    let kwargs = filter_opt [ Some ("num_mice", Py.Int.of_int num_mice) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let eat_part t ~num_mice () =
    let callable = Py.Object.find_attr_string t "eat" in
    let kwargs = filter_opt [ Some ("num_mice", Py.Float.of_float num_mice) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let jump t ~how_high () =
    let callable = Py.Object.find_attr_string t "jump" in
    let kwargs = filter_opt [ Some ("how_high", Py.Int.of_int how_high) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs

  let climb t ~how_high () =
    let callable = Py.Object.find_attr_string t "jump" in
    let kwargs = filter_opt [ Some ("how_high", Py.Int.of_int how_high) ] in
    ignore @@ Py.Callable.to_function_with_keywords callable [||] kwargs
end
