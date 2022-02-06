When missing penultimate unit arg, you get a halfway decent error
message.

  $ pyml_bindgen val_specs.txt na na | ocamlformat --name=a.ml -
  ("Error generating spec for 'val bad : t -> apple:int -> int'"
   ("Could not create py function from val_spec."
    "Val specs must specify attributes, instance, class, or module methods, or placeholders."
    "Unless you're defining an attribute, don't forget the penultimate unit argument!"
    ("The bad val_spec was:"
     ((fun_name bad)
      (args
       ((Positional ((type_ T))) (Labeled ((name apple) (type_ Int)))
        (Positional ((type_ Int)))))))))
