#!/bin/bash

set -e

if ! which ocaml &>/dev/null; then
    echo "Installing ocaml ..."
    sudo apt install opam
    opam init -y
    eval $(opam env --switch=default)
    opam install dune ocaml-lsp-server odoc ocamlformat utop
fi

(
    cd table
    eval $(opam config env)
    dune build
    dune exec table
)