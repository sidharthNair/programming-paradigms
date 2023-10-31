#!/bin/bash

set -e

if ! which ocaml &>/dev/null; then
    echo "Installing ocaml ..."
    sudo apt install opam
    opam init -y
    eval $(opam env --switch=default)
    opam install dune ocaml-lsp-server odoc ocamlformat utop
fi
