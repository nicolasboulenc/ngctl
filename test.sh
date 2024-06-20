#!/bin/bash

source nsm.sh

parse_port_test() {

    tests=(
        "listen 8080;"
	    "listen 192.168.1.1:8080;"
	    "listen 192.168.1.1:8080;"
	    "listen [2001:db8::1]:8080;"
	    "listen 443 ssl;"
	    "listen 80 default_server;"
	    "listen [2001:db8::1];" )

    for line in "${tests[@]}"; do
        port=$(nsm_parse_port "$line")
        printf "test=%-36s port=%-4s\n" "$line" "$port"
    done
}


test() {
    wget localhost:8080 -O test.txt -q
    res=$(cat test.txt)
    if [[ $res =~ "ok" ]]; then
        echo "success"
    else
        echo "failure"
    fi
}


parse_port_test

# NSM_BASE_PORT=9090 ./nsm.sh start
# test 9090
