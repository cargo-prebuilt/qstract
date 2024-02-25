#!/bin/bash

### Should be ran in the root directory of the cargo project
### BIN_LOC: Where the target folder is

set -euxo pipefail

: ${BIN_LOC:="./target/debug/qstract"}
QSTRACT_BIN="$(realpath $BIN_LOC)"
TEST_DIR="$(realpath ./test)"

TEMP_DIR="$(mktemp -d)"
pushd "$TEMP_DIR"

# Copy all test files
cp -r $TEST_DIR/* .
ls .

# Helpers
function 10_files {
    [ -e "$1/1.txt" ]
    [ -e "$1/2.txt" ]
    [ -e "$1/3.txt" ]
    [ -e "$1/4.txt" ]
    [ -e "$1/5.txt" ]
    [ -e "$1/6.txt" ]
    [ -e "$1/7.txt" ]
    [ -e "$1/8.txt" ]
    [ -e "$1/9.txt" ]
    [ -e "$1/10.txt" ]
}

function b101_files {
    [ -e "$1/ff1" ]
    [ -e "$1/ff2" ]
    [ -e "$1/ff101" ]
}

# Tests
function test_run {
    if ! $QSTRACT_BIN --version; then
        echo "Could not get qstract binary!"
        exit 1
    fi

    if ! $QSTRACT_BIN --help; then
        echo "Could not get qstract binary!"
        exit 1
    fi

    if ! $QSTRACT_BIN -h; then
        echo "Could not get qstract binary!"
        exit 1
    fi
}
test_run

function test_1 {
    $QSTRACT_BIN -z ./tarchive1.tar.gz -C ./t1
    10_files ./t1
    rm -rf ./t1

    $QSTRACT_BIN ./tarchive1.tar.gz -C ./t1 -z
    10_files ./t1

    $QSTRACT_BIN -C ./t1 -z ./tarchive1.tar.gz
    10_files ./t1
}

function test_2 {
    $QSTRACT_BIN -C ./em1 -z ./e1.tar.gz
    if [ ! -z "$(ls -A ./em1)" ]; then
        echo "Not empty"
        exit 1
    fi

    $QSTRACT_BIN -C ./em2 ./e1.tar
    if [ ! -z "$(ls -A ./em2)" ]; then
        echo "Not empty"
        exit 1
    fi
}

function test_3 {
    $QSTRACT_BIN t3archive.tar
    b101_files ./ff
}

test_1
test_2
test_3

popd
rm -rf "$TEMP_DIR"
