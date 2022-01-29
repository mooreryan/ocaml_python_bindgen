open Importing_modules_lib

let () = Py.initialize ()

let () = assert (3 = Silly_math.Add.add ~x:1 ~y:2 ())

let () = assert (-1 = Silly_math.Subtract.subtract ~x:1 ~y:2 ())

let () = assert ("sparkle, sparkle!!" = Magic_dust.Sparkles.sparkles ())

let () = assert ("hearts..." = Magic_dust.Hearts.hearts ())
