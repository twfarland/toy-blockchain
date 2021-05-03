# Toy blockchain

This is an OCaml port of the python toy blockchain described in https://hackernoon.com/learn-blockchains-by-building-one-117428612f46

I ported this to build a bit of intuition about basic blockchain concepts and to practice
the excellent OCaml language, which I haven't yet had a opportunity to use in the industry.

## Build / run a node

    dune build
    dune exec ./node.exe -- -p {PORT}

## Get a node's chain

    curl http://localhost:3000/chain

## Check chain validity

    curl http://localhost:3000/chain/valid

## Create a transaction

    curl --header "Content-Type: application/json" \
        --request POST \
        --data '{ "sender": "some-sender-address", "recipient": "some-recipient-address", "amount": 1 }' \
        http://localhost:3000/transaction

## mine on a node

    curl --request POST http://localhost:3000/mine

## register nodes with another node

    curl --header "Content-Type: application/json" \
        --request POST \
        --data '{ "nodes": ["127.0.0.1:3001"] }' \
        http://localhost:3000/nodes/register

## resolve node (run consensus across the network of registered nodes)

    curl --request POST http://localhost:3000/nodes/resolve
