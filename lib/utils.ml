open! Base

let is_space = function ' ' -> true | _ -> false

let is_capital_letter = function 'A' .. 'Z' -> true | _ -> false

let is_lowercase_letter = function 'a' .. 'z' -> true | _ -> false

let is_ok_for_name = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let read_python_source file_name = Stdio.In_channel.read_all file_name

module Angstrom_helpers = struct
  open Angstrom

  let is_whitepace = function ' ' | '\t' -> true | _ -> false

  let is_whitespace_or_eol = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false

  let eoi =
    let open Angstrom.Let_syntax in
    end_of_input
    <|> let%bind bad_thing = take_till is_whitespace_or_eol in
        fail bad_thing
        <?> "parser failed before all input was consumed at token"
end
