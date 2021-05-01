open Opium

let node_id = Uuidm.to_string (Uuidm.v `V4)

let network = ref (Network.create ())

let blockchain = ref (Blockchain.create ())

let error_json message = Response.of_json (`Assoc ["error", `String message])

let print_param_handler req =
  Printf.sprintf "Hello, %s\n" (Router.param req "name")
  |> Response.of_plain_text
  |> Lwt.return

let mine_handler _ =
  match Blockchain.mine !blockchain node_id with
  | Ok blockchain' ->
      blockchain := blockchain';
      let index = List.length !blockchain.chain in
      let json = `Assoc [ 
        "message", `String (Printf.sprintf "New block forged at index %d" index);
        "block", Block.block_to_yojson (List.hd !blockchain.chain)
      ]
      in Response.of_json json |> Lwt.return
  | Error message -> 
      error_json message |> Lwt.return        

let transaction_handler req =
  let open Lwt in
  Request.to_json_exn req >>= fun json ->
    
    return (
      match Transaction.transaction_of_yojson json with
      | Error message -> error_json message
      | Ok transaction ->

      match Blockchain.add_transaction !blockchain transaction with
      | Error message -> error_json message
      | Ok blockchain' ->
        blockchain := blockchain';
        Response.of_json (`Assoc [ 
          "message", `String (Printf.sprintf "Transaction will be added to block %d" (List.length !blockchain.chain))
        ])
    )

let chain_handler _ =
  Blockchain.blockchain_to_yojson !blockchain
  |> Response.of_json
  |> Lwt.return

let chain_valid_handler _ =
  let valid = Blockchain.valid_chain !blockchain.chain in
  Response.of_json (`Assoc ["valid", `Bool valid])
  |> Lwt.return

let nodes_register_handler req =
  let open Lwt in
  Request.to_json_exn req >>= fun json ->
    return (
      match Network.network_of_yojson json with
      | Error message -> error_json message
      | Ok { nodes } ->
        network := Network.register_nodes !network nodes;
        Response.of_json (`Assoc [ 
          "message", `String "New nodes have been added";
          "nodes", `List (List.map (fun node -> (`String node)) !network.nodes);
        ])
    )

let get_neighbour node_location =
  let open Lwt in
  let url = Uri.of_string (Printf.sprintf "http://%s/chain" node_location) in

  Cohttp_lwt_unix.Client.get url >>= fun (_, body) ->
    Cohttp_lwt.Body.to_string body >>= fun str ->
      Yojson.Safe.from_string str 
      |> Blockchain.blockchain_of_yojson
      |> return

let nodes_resolve_handler _ =
  let open Lwt in
  Blockchain.resolve_conflicts !blockchain !network get_neighbour >>= fun (blockchain', replaced) ->
    if replaced 
    then (
      blockchain := blockchain';
      Response.of_json (`Assoc [ 
        "message", `String "Our chain was replaced"
      ]) |> return
    ) else (
      Response.of_json (`Assoc [ 
        "message", `String "Our chain is authoritative"
      ]) |> return
    )

let _ =
  App.empty
  |> App.get "/hello/:name" print_param_handler
  |> App.post "/mine" mine_handler
  |> App.post "/transaction" transaction_handler
  |> App.get "/chain" chain_handler
  |> App.get "/chain/valid" chain_valid_handler
  |> App.post "/nodes/register" nodes_register_handler
  |> App.post "/nodes/resolve" nodes_resolve_handler
  |> App.run_command
