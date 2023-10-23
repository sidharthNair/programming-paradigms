#!/bin/bash

set -e

(
    cd antlr

    if [ ! -e thirdparty/antlr-4.13.1-complete.jar ]; then
        (
            mkdir -p thirdparty && cd thirdparty
            echo "Downloading antlr-4.13.1-complete.jar ..."
            curl -s -O https://www.antlr.org/download/antlr-4.13.1-complete.jar
        )
    fi

    if ! java --version |& grep 'build 11' >/dev/null; then
        echo "ERROR: Please use Java 11"
        exit 1
    fi

    if [ ! -e cmake/ ]; then
        (
            echo "Downloading antlr4 cpp runtime ..."
            curl -s -O https://www.antlr.org/download/antlr4-cpp-runtime-4.13.1-source.zip
            echo "Extracting cmake files ..."
            unzip -qq antlr4-cpp-runtime-4.13.1-source.zip "cmake/*"
            rm antlr4-cpp-runtime-4.13.1-source.zip
        )
    fi

    echo "Building ..."
    cmake -Wno-dev -DCMAKE_BUILD_TYPE=Release .
    make -j $(nproc --all)

    printf "Running executable ...\n\n"
    ./cypher
)