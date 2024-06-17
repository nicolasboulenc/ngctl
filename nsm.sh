#!/bin/bash

# to fix
# check for requirement (awk, nginx, /etc/nginx/sites-available, /etc/nginx/sites-enabled, systemctl)
# imporve port parsing

VERSION=0.1
DEFAULT_PORT=8080
SITES_ENABLED="/etc/nginx/sites-enabled/"
SITES_AVAILABLE="/etc/nginx/sites-available/"

read -d '\n' template_text << EndOfText
server {
    listen %i;
    root %s;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EndOfText

read -d '\n' version_template << EndOfText
ngrol version: $VERSION
  -> nginx version:	%s
  -> systemd version:	%s
  -> awk version:	%s
  -> sites-available:	%s
  -> sites-enabled:	%s
EndOfText

read -d '\n' help_template << EndOfText
nsm start [path=.] [port=%i]
	nsm start
	nsm start .
	nsm start 8082
	nsm start /home/nicolas/dev
	nsm start /home/nicolas/dev 8088
	nsm start . 8083
nsm add [path] [port]
nsm del [path]
nsm ls
nsm enable [path]
nsm disable [path] 
nsm version
EndOfText


declare -a servers
declare -i servers_idx=1
declare server_port=""
declare server_root=""
declare -a ports


nsm_print_confs() {
	local path=$1
	local desc=$2
	servers_idx=$3

	t=$(ls -1 "${path}"nsm.* 2>/dev/null)
	status=$?
	if [ ! $status -eq 0 ]; then
		printf "Nothing to action.\n"
		exit
	fi

	# for file in "${path}"nsm.*; do
	while read file; do
		local port=""
		local root=""
		while read line; do
			if [[ "$line" =~ listen ]]; then
				port="${line##listen* }"
				port="${port%%;}"
				continue
			fi
			if [[ "$line" =~ root ]]; then
				root="${line##root* }"
				root="${root%%;}"
				continue
			fi
			if [[ -n $port && -n $root ]]; then
				break
			fi
		done < $file
		printf "[%i] %-48s http://localhost:%-15s (%s)\n" "$servers_idx" "${root}" "${port}" "${desc}";
		let "servers_idx+=1"
	done <<< $t
}


nsm_get_conf_details() {

	local file=$1
	server_port=""
	server_root=""
	while read line; do
		if [[ "$line" =~ listen ]]; then
			server_port="${line##listen* }"
			server_port="${server_port%%;}"
			continue
		fi
		if [[ "$line" =~ root ]]; then
			server_root="${line##root* }"
			server_root="${server_root%%;}"
			continue
		fi
		if [[ -n $server_port && -n $server_root ]]; then
			break
		fi
	done < $file
}


nsm_get_ports() {

	i=1
	for file in "${SITES_ENABLED}"*; do
		while read line; do
			if [[ "$line" =~ listen ]]; then
				port="${line##listen }"
				port="${port%%;}"
				ports[$i-1]=$port
				break
			fi
		done < $file
		# printf "[%i] %-36s %-5s (%s)\n" "$i" "$file" "${port}" "enabled";
		let "i+=1"
	done
	for file in "${SITES_AVAILABLE}"*; do
		while read line; do
			if [[ "$line" =~ listen ]]; then
				port="${line##listen }"
				port="${port%%;}"
				ports[$i-1]=$port
				break
			fi
		done < $file
		# printf "[%i] %-36s %-5s (%s)\n" "$i" "$file" "${port}" "enabled";
		let "i+=1"
	done
}


nsm_find_port_available() {

	nsm_get_ports

	port=$DEFAULT_PORT
	while [[ " ${ports[*]} " =~ " ${port} " ]]; do
		let "port+=1"
	done
	echo $port
}


case "$1" in

	"start" )
		location=$(pwd)"/"
		port=""

		# check for 2nd argument
		if ! [ -z "$2" ]; then
			# check if argument is a number
			if [[ "$2" =~ ^[0-9]+$ ]]; then
				# this is a port number
				port="$2"
			else
				# this should be a path
				if [ -d "$2" ]; then
					pushd "$2" >/dev/null 2>&1
					location=$(pwd)"/"
					popd >/dev/null 2>&1
				else
					printf "Error: location does not exist!"
					exit 1
				fi
			fi
		fi

		# check for 3rd argument
		if ! [ -z "$3" ]; then
			# check if argument is a number
			if [[ "$3" =~ ^[0-9]+$ ]]; then
				# this is a port number
				port="$3"
			else
				printf "Error: port should be a number!"
				exit 1
			fi
		fi

		fn="nsm${location////.}"
		fn="${fn::-1}"
		pe="$SITES_ENABLED$fn"
		pa="$SITES_AVAILABLE$fn"

		if [ -z $port ] && ( [ -f $pa ] || [ -f $pe ] ); then
			printf 'Existing entry...\n'
			if [ -f $pa ]; then
				mv "$pa" "$pe"
			fi
			# todo get port from file
			while read line; do
				is_listen=$(echo $line | awk '{print $1}')
				if [[ "$is_listen" == *"listen"* ]]; then
					port=$(echo $line | awk '{print $2}')
				fi
			done < "${pe}"
		else
			if [ -n $port ]; then
				port=$(nsm_find_port_available)
			fi
			# printf 'New entry...\n'
			printf "$template_text\n" $port "$location" > "$pe"
		fi

		$(nginx -t)
		$(systemctl restart nginx.service)
		printf "\nlocation enabled: %s\n" $location
		printf " --> http://localhost:%i/\n" $port
	;;


	"enable" )
		nsm_print_confs "${SITES_AVAILABLE}" "disabled" 1
		read -p "Enter location number to enable: " option
		file="${servers[$option-1]##/*/}"
		mv "${SITES_AVAILABLE}${file}" "${SITES_ENABLED}${file}"
		systemctl restart nginx.service
		nsm_get_conf_details "${SITES_ENABLED}${file}"
		printf " -> %-36s http://localhost:%-5s (enabled)\n" "${server_root}" "${server_port}"
	;;


	"disable" )
		nsm_print_confs "${SITES_ENABLED}" "enabled" 1
		read -p "Enter location number to disable: " option
		file="${servers[$option-1]##/*/}"
		mv "${SITES_ENABLED}${file}" "${SITES_AVAILABLE}${file}"
		systemctl restart nginx.service
		nsm_get_conf_details "${SITES_AVAILABLE}${file}"
		printf " -> %-36s http://localhost:%-5s (disabled)\n" "${server_root}" "${server_port}"
	;;


	"ls" )
		nsm_print_confs "${SITES_ENABLED}" "enabled" 1
		nsm_print_confs "${SITES_AVAILABLE}" "available" "$servers_idx"
	;;


	"status" )
		# Assumes active is line 3
		status=$(systemctl status nginx.service | 
			while read line; do
				if [[ "$line" =~ Active: ]]; then
					status="${line##Active: }"
					status="${status%%(*}"
					printf "%s" "$status"
					break
				fi
			done)
		printf 'nginx.service is %s\n' $status 
	;;


	"version" )
		ngx_version=$(nginx -V 2>&1 | head --lines=1 | awk '{print $3}' | awk -F '/' '{print $2}')
		smd_version=$(systemctl --version 2>&1 | head --lines=1 | awk '{print $2}')
		awk_version=$(awk --version 2>&1 | head --lines=1 | awk '{print $2}')
		sites_enabled="not found"
		sites_available="not found"
		if [ -d $SITES_AVAILABLE ]; then
			sites_available="found"
		fi
		if [ -d $SITES_ENABLED ]; then
			sites_enabled="found"
		fi
		printf "$version_template\n" $ngx_version $smd_version $awk_version $sites_available $sites_enabled
	;;


	"help" )
		printf '%s\n' "$help_template"
	;;


	* )
		echo "Try 'nsm.sh help' for more information." 
	;;

esac
exit 0

