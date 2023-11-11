open Yojson.Basic

let parse_record (record : Yojson.Basic.t) =
  match record with
  | `Assoc fields ->
    let keys = List.assoc "Keys" fields in
    let values = List.assoc "Values" fields in
    (match (keys, values) with
    | (`List key_list, `List value_list) ->
      List.iter2
        (fun key value ->
            Printf.printf "%s %s\n" (to_string key) (to_string value)
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

let () = parse_json "../antlr/response.json"
