#!/bin/bash

# NOTE: do NOT modify this file.

set -e

if [ ! -e antlr-4.9.2-complete.jar ]; then
        curl -O https://www.antlr.org/download/antlr-4.9.2-complete.jar
fi

cp="$(pwd)/antlr-4.9.2-complete.jar"
test="$(pwd)/tests/0.prog"

if ! java --version |& grep 'java 17' > /dev/null; then
        echo "ERROR: Please use Oracle Java 17 (https://www.oracle.com/java/technologies/downloads)"
        exit 1
fi

echo "Processing grammar ..."
( cd code
  java -Xmx500M -cp ${cp} org.antlr.v4.Tool -visitor SimpleLang.g4
  javac -cp ${cp} *.java )

echo "Running one input example ..."
( cd code
  ./simple ${test} )
