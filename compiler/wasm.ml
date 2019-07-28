open List_utils
open Binary

type func_sig = { params: int; results: int }

type imported_func = { import_name: string * string; signature: func_sig }

type exported_func = { export_name: string; signature: func_sig; locals: int; code: int list }

type func =
  | ImportedFunc of imported_func
  | Func of { signature: func_sig; locals: int; code: int list }
  | ExportedFunc of exported_func

type imported_mem = { module_name: string * string; limits: bool; initial: int }

type mem =
  | Mem of { limits: bool; initial: int }
  | ImportedMem of imported_mem

type wasm = {
  global_vars: int list list;
  functions: func list;
  memories: mem list
}

let sig_of_func = function
  | ImportedFunc { signature } -> signature
  | Func { signature } -> signature
  | ExportedFunc { signature } -> signature

let types_of_functions =
  let collect table func =
    let signature = sig_of_func func in
    if List.mem signature table then table else signature :: table
  in
  List.fold_left collect []

let header = to_uint32 1836278016 @ to_uint32 1

let type_section types functions =
  if List.length types = 0
    then []
    else
      let num_types = leb128_of_int @@ List.length types in
      let type_decls =
        types
        |> concatMap (fun { params; results } ->
          96 (* func *)
          :: params (* num params *)
          :: make_list params 127 (* i32 *)
          @ results (* num results *)
          :: make_list results 127 (* i32 *))
      in
      1 (* section code *)
      :: leb128_of_int (List.length num_types + List.length type_decls) (* section size *)
      @ num_types
      @ type_decls

let imports_of_functions = List.fold_left (fun imports -> function
  | ImportedFunc decl -> decl :: imports
  | _ -> imports) []

let imports_of_memories = List.fold_left (fun imports -> function
  | ImportedMem decl -> decl :: imports
  | _ -> imports) []

let chars_of_string str = List.map Base.Char.to_int @@ Base.String.to_list str

let import_section types functions memories =
  let imported_functions =
    imports_of_functions functions
    |> List.map (fun { import_name; signature } ->
      (String.length @@ fst import_name)
      :: (chars_of_string (fst import_name))
      @ (String.length @@ snd import_name)
      :: (chars_of_string (snd import_name))
      @ 0 (* import kind *)
      :: leb128_of_int (find signature types))
  in
  let imported_memories =
    imports_of_memories memories
    |> List.map (fun { module_name; limits; initial } ->
      (String.length @@ fst module_name)
      :: (chars_of_string (fst module_name))
      @ (String.length @@ snd module_name)
      :: (chars_of_string (snd module_name))
      @ 2 (* import kind *)
      :: (if limits then 1 else 0)
      :: [initial])
  in
  let entries = imported_functions @ imported_memories in
  if List.length entries = 0
    then []
    else
      let num_imports = leb128_of_int @@ List.length entries in
      let body = num_imports @ List.concat entries in
      2 (* section code *)
      :: leb128_of_int (List.length body) (* section size *)
      @ body

let function_section types functions =
  if List.length functions = 0
    then []
    else
      let body =
        leb128_of_int (List.length functions) (* num functions *)
        @
        (functions
        |> List.map (fun f -> find (sig_of_func f) types)) (* function n signature index *)
      in
      3 (* section code *)
      :: leb128_of_int (List.length body) (* section size *)
      @ body

let memory_section memories =
  if List.length memories = 0
    then []
    else
      let body =
        leb128_of_int (List.length memories) (* num memories *)
        @
        (memories
        |> concatMap (function
          | ImportedMem { module_name = _; limits; initial }
          | Mem { limits; initial } ->
              [if limits then 1 else 0; initial]))
      in
      5 (* section code *)
      :: leb128_of_int (List.length body) (* section size *)
      @ body

let global_section global_vars =
  if List.length global_vars > 0
    then
      let body =
        leb128_of_int (List.length global_vars) @ List.concat (List.map (fun code -> [127; 1] @ code @ [11]) global_vars)
      in
      6 :: leb128_of_int (List.length body) @ body
    else []

let exports_of_functions =
  let index = ref (-1) in
  List.fold_left (fun exports ->
    index := !index + 1;
    function
      | ExportedFunc decl -> (!index, decl) :: exports
      | _ -> exports) []

let export_section functions =
  let exported_functions =
    exports_of_functions functions
    |> List.map (fun (index, { export_name }) ->
      String.length export_name (* string length *)
      :: (List.map Base.Char.to_int @@ Base.String.to_list export_name)
      @ 0 (* export kind *)
      :: [index (* export func index *)])
  in
  if List.length exported_functions = 0
    then []
    else
      let num_exports = leb128_of_int @@ List.length exported_functions in
      let body = num_exports @ List.concat exported_functions in
      7 (* section code *)
      :: List.length body (* section size *)
      :: body

let code_section functions =
  let num_functions =
    List.length functions - (List.length @@ imports_of_functions functions)
  in
  if num_functions = 0
    then []
    else
      let body =
        leb128_of_int num_functions @
        (functions
        |> concatMap (function
          | ImportedFunc _ -> []
          | ExportedFunc { locals; code } | Func { locals; code } ->
              if locals = 0
                then
                  (leb128_of_int @@ List.length code + 2) (* func body size *)
                  @ 0 (* local decl count *)
                  :: code
                  @ [11 (* end *)]
                else
                  (leb128_of_int @@ List.length code + 4) (* func body size *)
                  @ 1 (* local decl count *)
                  :: locals (* local type count *)
                  :: 127 (* i32 *)
                  :: code
                  @ [11 (* end *)]))
      in
      10 (* section code *)
      :: leb128_of_int (List.length body) (* section size *)
      @ body

let bin_of_wasm { functions; memories; global_vars } =
  let types = types_of_functions functions in
  header
  @ type_section types functions
  @ import_section types functions memories
  @ function_section types functions
  @ memory_section memories
  @ global_section global_vars
  @ export_section functions
  @ code_section functions
