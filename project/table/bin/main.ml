open Yojson.Basic

let table = ref []
let key_types = ref []

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
                  if not (List.mem_assoc (to_string key) !key_types) then
                    key_types := !key_types @ [(to_string key, "edge")];
              else if List.mem_assoc "Labels" dict then
                let node = Printf.sprintf "%s %s %s"
                  (to_string (List.assoc "Id" dict))
                  (to_string (List.assoc "Labels" dict))
                  (to_string (List.assoc "Props" dict)) in
                  column := !column @ [node];
                if not (List.mem_assoc (to_string key) !key_types) then
                  key_types := !key_types @ [(to_string key, "node")];
            | _ ->
              column := !column @ [(to_string value)];
              if not (List.mem_assoc (to_string key) !key_types) then
                let is_int =
                  (match int_of_string_opt (to_string value) with
                  | Some _ -> true
                  | None -> false) in
                if is_int then
                  key_types := !key_types @ [(to_string key, "int")]
                else if (to_string value) <> "null" then
                  key_types := !key_types @ [(to_string key, "str")]
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
    Printf.printf "%-15s | " (key ^ " (" ^
      (if List.mem_assoc key !key_types then List.assoc key !key_types else "null")
      ^ ")");
    List.iter (fun value ->
      Printf.printf "%-15s | " value
    ) !column;
    print_newline ()
  ) !table

let rec count_column acc column =
  match column with
  | [] -> acc
  | elem :: tail ->
    if elem = "null" then
      count_column acc tail
    else
      count_column (acc + 1) tail

let rec sum_column acc column =
  match column with
  | [] -> acc
  | elem :: tail ->
    if elem = "null" then
      sum_column acc tail
    else
      sum_column (acc + int_of_string elem) tail

let count_type key_type =
  List.fold_left (fun acc (key, values) ->
    if List.mem_assoc key !key_types && (List.assoc key !key_types) = key_type then
      count_column acc !values
    else
      acc) 0 !table

let print_averages () =
  List.iter (fun (key, key_type) ->
    if key_type = "int" then
      let values = List.assoc key !table in
      let sum = sum_column 0 !values
      and count = count_column 0 !values in
      Printf.printf "Average of %s: %.3f\n" key (float_of_int sum /. float_of_int count)
  ) !key_types

let () =
  parse_json "../antlr/response.json";
  print_table ();
  Printf.printf "Number of nodes: %d\n" (count_type "node");
  Printf.printf "Number of edges: %d\n" (count_type "edge");
  Printf.printf "Number of integers: %d\n" (count_type "int");
  Printf.printf "Number of strings: %d\n" (count_type "str");
  print_averages ()
