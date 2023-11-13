open Yojson.Basic

let table = ref []
let key_type = ref []

let parse_record record =
  match record with
  | `Assoc fields ->
    let keys = List.assoc "Keys" fields
    and values = List.assoc "Values" fields in
    (match (keys, values) with
    | (`List key_list, `List value_list) ->
      List.iter2
        (fun key value ->
          (if not (List.mem_assoc (to_string key) !table) then
            table := !table @ [((to_string key), ref [])]);
          let column = List.assoc (to_string key) !table in
            match value with
            | `Assoc dict ->
              if List.mem_assoc "Type" dict then
                let edge = Printf.sprintf "%s (%s)-[%s]-(%s) %s"
                  (to_string (List.assoc "Id" dict))
                  (to_string (List.assoc "StartId" dict))
                  (to_string (List.assoc "Type" dict))
                  (to_string (List.assoc "EndId" dict))
                  (to_string (List.assoc "Props" dict)) in
                  column := !column @ [edge];
                  if ((List.mem_assoc (to_string key) !key_type) &&
                    (List.assoc (to_string key) !key_type) == "str") then
                    key_type := List.remove_assoc (to_string key) !key_type;
                  if not (List.mem_assoc (to_string key) !key_type) then
                    key_type := !key_type @ [(to_string key, "edge")];
              else if List.mem_assoc "Labels" dict then
                let node = Printf.sprintf "%s %s %s"
                  (to_string (List.assoc "Id" dict))
                  (to_string (List.assoc "Labels" dict))
                  (to_string (List.assoc "Props" dict)) in
                  column := !column @ [node];
                if ((List.mem_assoc (to_string key) !key_type) &&
                  (List.assoc (to_string key) !key_type) == "str") then
                  key_type := List.remove_assoc (to_string key) !key_type;
                if not (List.mem_assoc (to_string key) !key_type) then
                  key_type := !key_type @ [(to_string key, "node")];
            | _ ->
              column := !column @ [(to_string value)];
              if not (List.mem_assoc (to_string key) !key_type) then
                let is_int =
                  (match int_of_string_opt (to_string value) with
                  | Some _ -> true
                  | None -> false) in
                if is_int then
                  key_type := !key_type @ [(to_string key, "int")]
                else
                  key_type := !key_type @ [(to_string key, "str")]
        ) key_list value_list
    | _ ->
      Printf.printf "Invalid record.\n"
    )
  | _ ->
    Printf.printf "Invalid record.\n"

let parse_json filename =
  let json = from_file filename in
  match json with
  | `Assoc fields ->
    let records = List.assoc "Records" fields in
    (match records with
    | `List record_list ->
      List.iter (fun record ->
        parse_record record
      ) record_list
    | _ ->
      Printf.printf "No records found.\n"
    )
  | _ ->
    Printf.printf "JSON file does not contain an object.\n"

let print_table () =
  Printf.printf "%-15s | %-15s\n" "Key" "Values";
  Printf.printf "%s | %s\n" (String.make 15 '-') (String.make 15 '-');
  List.iter (fun (key, column) ->
    Printf.printf "%-15s | " (key ^ " (" ^ (List.assoc key !key_type) ^ ")");
    List.iter (fun value ->
      Printf.printf "%-15s | " value
    ) !column;
    print_newline ()
  ) !table

let () =
  parse_json "../antlr/response.json";
  print_table ()
