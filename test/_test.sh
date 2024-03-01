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
    rm -rf ./ff
}

function test_4 {
    $QSTRACT_BIN --zip ./zarchive1.zip -C ./t1
    10_files ./t1
    rm -rf ./t1

    $QSTRACT_BIN ./zarchive1.zip -C ./ --zip
    10_files ./
    rm -rf *.txt

    $QSTRACT_BIN -C ./t555/111 --zip ./zarchive1.zip
    10_files ./t555/111
    rm -rf ./t555
}

function test_5 {
    $QSTRACT_BIN --zip ./7z-zarchive1.zip -C ./t1
    10_files ./t1
    rm -rf ./t1

    $QSTRACT_BIN ./7z-zarchive1.zip -C ./ --zip
    10_files ./
    rm -rf *.txt

    $QSTRACT_BIN -C ./t555/111 --zip ./7z-zarchive1.zip
    10_files ./t555/111
    rm -rf ./t555
}

function test_6 {
    $QSTRACT_BIN --zip nocomp1.zip
    b101_files ./ff
    rm -rf ./ff

    $QSTRACT_BIN --zip nocomp1.zip -C ./ttf
    b101_files ./ttf/ff
    rm -rf ./ttf/ff
}

function test_7 {
    $QSTRACT_BIN --sha256 ./tarchive1.tar.gz | grep 'dfd5fe115d931b6c4e4860391fc3984ab4ec5b6110851c0ef5a8641bd079f2c2' &>/dev/null
    [ $? != 0 ] && exit 2

    $QSTRACT_BIN ./tarchive1.tar.gz --sha512 | grep 'a73f29153d74694323e8d0bb82a910018a05ce011c73dfdca62b9fca3aafc218b92f2ff277a4b8006a919874527843d2ba0d56c0d5532487ac0a1d84421b5539' &>/dev/null
    [ $? != 0 ] && exit 2

    $QSTRACT_BIN ./tarchive1.tar.gz --sha3_256 | grep '60e99497952e17852d63c843606a214945550ccbb6777db25f7405fb39b55025' &>/dev/null
    [ $? != 0 ] && exit 2

    $QSTRACT_BIN --sha3_512 ./tarchive1.tar.gz | grep '2b292cf7c24d023e5f4b836ff36640b1a6b40d94382feab658b7c5ac5aa65ba7bdad2756e2c1c3077dd446b4474bdad72e96a030d0a291408482ac668246e4a' &>/dev/null
    [ $? != 0 ] && exit 2

    if [ "$($QSTRACT_BIN --sha512 -z ./e1.tar)" ]; then
        exit 1
    fi

    if [ "$($QSTRACT_BIN --sha256 --sha512 ./e1.tar)" ]; then
        exit 1
    fi
}

test_1
test_2
test_3
test_4
test_5
test_6

# TODO: Test hashing
test_7

popd
rm -rf "$TEMP_DIR"
