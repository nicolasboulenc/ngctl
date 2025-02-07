#!/bin/bash

source nsm.sh

parse_port_test() {

    printf "%s\n" "*** nsm_parse_port *************************************************"

    tests=(
        "listen 8080;"
	    "listen 192.168.1.1:8081;"
	    "listen 192.168.1.1:8082;"
	    "listen [2001:db8::1]:8083;"
	    "listen 443 ssl;"
	    "listen 80 default_server;"
	    "listen [2001:db8::1];" )

    valid=(
        "8080"
        "8081"
        "8082"
        "8083"
        "443"
        "80"
        ""
    )

    local found=""
    local expected=""

    for (( i=0; i<"${#tests[@]}"; i++ )); do
        test="${tests[$i]}"
        port=$(nsm_parse_port "$test")
        result=$([[ "$port" = "${valid[$i]}" ]] && echo "success" || echo "failure")
        
        printf -v found "found=|%s|" "$port"
        printf -v expected "expected=|%s|" "${valid[$i]}"
        printf "test=%-36s %-20s %-20s %s\n" "$test" "$found" "$expected" "$result"
    done
    printf "\n"
}


test_start() {

    printf "%s\n" "*** nsm_start *************************************************"

    # nsm start
	# nsm start .
	# nsm start 8083
	# nsm start /home/nicolas/dev
	# nsm start /home/nicolas/dev 8088
	# nsm start ./test-site-3 8083

    # test 1
    command="./nsm.sh start"
    port="8080"
    pushd test-site-1 >> ./test.log
    ../nsm.sh start >> ../test.log
    popd >> ../test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    # test 2
    command="./nsm.sh start ."
    port="8081"
    pushd ./test-site-2 >> ./test.log
    ../nsm.sh start . >> ../test.log
    popd >> ../test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    # test 3
    port="8083"
    command="./nsm.sh start $port"
    pushd ./test-site-3 >> ./test.log
    ../nsm.sh start "$port" >> ../test.log
    popd >> ../test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    ./nsm.sh remove-all
    sleep 1

    # test 4
    port="8080"
    command="./nsm.sh start $(pwd)/test-site-1"
    ./nsm.sh start "$(pwd)/test-site-1" >> ./test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    # test 5
    port="8082"
    command="./nsm.sh start $(pwd)/test-site-2"
    ./nsm.sh start "$(pwd)/test-site-2" "$port" >> ./test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    # test 6
    port="8081"
    command="./nsm.sh start ./test-site-3"
    ./nsm.sh start "./test-site-3" >> ./test.log

    wget localhost:"$port" -O ./test.txt -q
    req=$(<./test.txt)
    res=$([[ $req =~ "ok" ]] && echo "success" || echo "failure")
    printf "cmd=%-58s port=%-15s %s\n" "$command" "$port" "$res"
    sleep 1

    ./nsm.sh remove-all
    sleep 1

    printf "\n"
}





parse_port_test
test_start

# NSM_BASE_PORT=9090 ./nsm.sh start
# test 9090
