
type transaction =
  {
    sender : string;
    recipient : string;
    amount : int;
  } [@@deriving show, yojson]
