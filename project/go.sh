#!/bin/bash

set -e

if ! which go &>/dev/null; then
    if ! [ -d /usr/local/go ]; then
        echo "Installing go ..."
        wget https://dl.google.com/go/go1.21.3.linux-amd64.tar.gz
        sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.21.3.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo "export PATH=\$PATH:/usr/local/go/bin" >>~/.bashrc
        rm go1.21.3.linux-amd64.tar.gz
    fi
    export PATH=$PATH:/usr/local/go/bin
fi

go version
(
    cd server
    go run server.go
)
