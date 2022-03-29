Errors

  $ combine_rec_modules
  combine_rec_modules: required argument FILE is missing
  Usage: combine_rec_modules [OPTION]… FILE…
  Try 'combine_rec_modules --help' for more information.
  [1]
  $ combine_rec_modules missing.ml
  ERROR -- File missing.ml does not exist
  [1]
  $ combine_rec_modules missing.ml missing2.ml
  ERROR -- These files do not exist: missing.ml, missing2.ml
  [1]

If you only see one module, exit with an error.  It doesn't make sense to run it
if there is only one module.

  $ combine_rec_modules d.ml
  module rec Donut : sig
    type t
  end = struct
    type t
  end
  ERROR -- I only saw one module in the input files
  [1]

If you don't see any modules, exit with an error.

  $ combine_rec_modules no_modules.ml
  let x = 1
  ERROR -- I didn't see any modules in the input files
  [1]

Basic usage 

  $ combine_rec_modules abc.ml
  module rec Apple_pie2 : sig
    type t
  end = struct
    type t
  end
  
  and Bike__thing__242__ : sig
    type t
  end = struct
    type t
  end
  
  and Cake : sig
    type t
  end = struct
    type t
  end
  $ combine_rec_modules d.ml e.ml
  module rec Donut : sig
    type t
  end = struct
    type t
  end
  and Extra : sig
    type t
  end = struct
    type t
  end
  $ combine_rec_modules abc.ml d.ml e.ml
  module rec Apple_pie2 : sig
    type t
  end = struct
    type t
  end
  
  and Bike__thing__242__ : sig
    type t
  end = struct
    type t
  end
  
  and Cake : sig
    type t
  end = struct
    type t
  end
  and Donut : sig
    type t
  end = struct
    type t
  end
  and Extra : sig
    type t
  end = struct
    type t
  end

It works okay when there is more than just the module on the line.

  $ combine_rec_modules one_line.ml
  module rec A_a__3 : sig type t end = struct type t end
  
  and Bike : sig type t end = struct type t end
  
  and Cake_icing : sig type t end = struct type t end

It does NOT check if you have a signature.

  $ combine_rec_modules no_sig.ml
  module rec A = struct
    type t
  end
  
  and B = struct
    type t
  end
