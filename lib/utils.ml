let is_space = function ' ' -> true | _ -> false

let is_capital_letter = function 'A' .. 'Z' -> true | _ -> false

let is_lowercase_letter = function 'a' .. 'z' -> true | _ -> false

let is_ok_for_name = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false
