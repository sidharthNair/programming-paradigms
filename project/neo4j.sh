#!/bin/bash

set -e

if ! which daemon &>/dev/null; then
    echo "Installing daemon ..."
    sudo apt-get install daemon
fi

if ! which cypher-shell &>/dev/null; then
    echo "Installing cypher-shell 4.4.22 ..."
    wget https://dist.neo4j.org/cypher-shell/cypher-shell_4.4.22_all.deb
    sudo dpkg -i cypher-shell_4.4.22_all.deb
    rm cypher-shell_4.4.22_all.deb
fi

if ! which neo4j &>/dev/null; then
    echo "Installing neo-4j 4.4.25 ..."
    wget https://dist.neo4j.org/deb/neo4j_4.4.25_all.deb
    sudo dpkg -i neo4j_4.4.25_all.deb
    rm neo4j_4.4.25_all.deb
fi

sudo neo4j start
echo "Server started, use \"cypher-shell\" to run the cypher CLI and \"sudo neo4j stop\" to stop the server."
