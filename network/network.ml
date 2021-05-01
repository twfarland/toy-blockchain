module SS = Set.Make(String)

type network =
  {
    nodes : string list
  }[@@deriving show, yojson]

let register_nodes network addresses =
  let open SS in
  let next_nodes = union (of_list network.nodes) (of_list addresses) in
  {
    nodes = next_nodes |> to_seq |> List.of_seq
  }

let create () = { nodes = [] }

