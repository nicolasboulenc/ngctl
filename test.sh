#!/bin/bash

test() {
    wget localhost:8080 -O test.txt -q
    res=$(cat test.txt)
    if [[ $res =~ "ok" ]]; then
        echo "success"
    else
        echo "failure"
    fi
}


NSM_BASE_PORT=9090 ./nsm.sh start
test 9090
