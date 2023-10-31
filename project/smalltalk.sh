#!/bin/bash

set -e

(
    cd pharo

    if [ ! -e pharo ]; then
        (
            echo "Downloading pharo vm ..."
            wget http://files.pharo.org/get-files/110/pharo-vm-Linux-x86_64-stable.zip
            unzip -qq pharo-vm-Linux-x86_64-stable.zip
            rm pharo-vm-Linux-x86_64-stable.zip
        )
    fi

    if [ ! -e pharo.version ]; then
        (
            echo "Downloading pharo image ..."
            wget https://files.pharo.org/get-files/110/pharo64.zip
            unzip -qq pharo64.zip
            rm pharo64.zip
        )
    fi

    ./pharo Pharo11-SNAPSHOT*.image visualize.st

)
