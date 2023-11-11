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

    if ! which sqlite3 &>/dev/null; then
        echo "Installing sqlite ..."
        wget https://www.sqlite.org/2023/sqlite-autoconf-3440000.tar.gz
        tar xvfz sqlite-autoconf-3440000.tar.gz
        (
            cd sqlite-autoconf-3440000
            ./configure --prefix=/usr/local
            make
            sudo make install
        )
        rm -rf sqlite-autoconf-3440000
        rm sqlite-autoconf-3440000.tar.gz
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

    if [ "$#" -eq 0 ]; then
        printf "Running executable ...\n\n"
        ./cypher
    elif [ "$#" -eq 2 ]; then
        command=$1
        runs=$2
        if ! [[ "$runs" =~ ^[0-9]+$ ]]; then
            echo "Error: number of runs must be an integer"
            exit 1
        fi

        printf "Running \"$command\" $runs times. Logging output to benchmark.log ...\n\n"
        printf "Running \"$command\" $runs times.\n" >../benchmark.log

        runtimes=()
        for i in $(seq 1 1 "$runs"); do
            start_time=$(date +%s%3N)
            ./cypher "$command" >>../benchmark.log
            end_time=$(date +%s%3N)
            elapsed_time=$(($end_time - $start_time))
            printf "Runtime: $elapsed_time ms\n\n" >>../benchmark.log
            runtimes+=($elapsed_time)
        done

        total=0
        for runtime in "${runtimes[@]}"; do
            total=$(($total + $runtime))
        done

        average_runtime=$(printf %.3f "$((10 ** 9 * $total / $runs))e-9")
        echo "Average runtime: $average_runtime ms"

    else
        echo "Error: arguments must be the command to run in quotes, followed by the number of runs"
        exit 1
    fi
)
