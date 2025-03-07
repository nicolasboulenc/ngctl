#!/bin/bash

if [ -z "$NGCTL_ENABLED" ]; then
	echo "Error: Unable to find NGCTL_ENABLED folder!"
	echo "ngctl-env.sh might not be loaded by your .bashrc file!"
	exit 1
fi

VERSION=0.1
DEFAULT_PORT=8080

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
Usage: ngctl [COMMAND] [PATH] [PORT]
Easily manage nginx conf files

  start [PATH=.] [PORT=%i]    Starts a server with path as root. If not port is provided, will use first available port from 8080.
  add   [PATH=.] [PORT=%i]    Alias for start.
  del   [PATH]                NOT IMPLEMENTED
  ls                          List all servers, enabled and available.
  enable                      Enable a previously disabled server.
  disable                     Disable a previously enabled server.
  version                     Display version information.
EndOfText


declare -a servers_files=()
declare -i servers_idx=1
declare server_port=""
declare server_root=""


ngctl_print_confs() {

	local path=$1
	local desc=$2
	servers_idx=$3
	servers_files=()

	for file in "${path}"ngctl.*; do
		if [ ! -f "${file}" ]; then
			if [ ${servers_idx} = 1 ]; then
  				echo "No files found..."
			fi
			break
		fi

		servers_files+=("${file}")
		local port=""
		local root=""
		local line=""
		readarray -t lines < <(cat "${file}")
		for line in "${lines[@]}"; do

			if [[ "${line}" =~ listen ]]; then
				port="${line##* listen* }"
				port="${port%%;}"
			fi
			if [[ "${line}" =~ root ]]; then
				root="${line##* root* }"
				root="${root%%;}"
			fi
			if [[ -n $port && -n $root ]]; then
				printf "[%i] %-48s http://localhost:%-15s (%s)\n" "$servers_idx" "${root}" "${port}" "${desc}";
				break
			fi
		done
		servers_idx=$((servers_idx+1))
	done
}


ngctl_get_conf_port() {

	local file=$1
	local port=0
	if [ ! -f "${file}" ]; then
		echo ${port}
	fi
	readarray -t lines < <(cat "${file}")
	for line in "${lines[@]}"; do
		if [[ "$line" =~ listen ]]; then
			port="${line##* listen* }"
			port="${port%%;}"
			break
		fi
	done
	echo ${port}
}


ngctl_get_conf_root() {

	local file=$1
	local root=""
	if [ ! -f "${file}" ]; then
		echo "${root}"
	fi
	readarray -t lines < <(cat "${file}")
	for line in "${lines[@]}"; do
		if [[ "$line" =~ root ]]; then
			root="${line##* root* }"
			root="${root%%;}"
			continue
		fi
	done
	echo "${root}"
}


ngctl_find_port_available() {

	local i=1
	local ports
	for file in "${NGCTL_ENABLED}"*; do
		if [ ! -f "${file}" ]; then
			break
		fi
		cat "${file}" | while read line; do
			if [[ "$line" =~ listen ]]; then
				port="${line##listen }"
				port="${port%%;}"
				ports[$i-1]=$port
				break
			fi
		done
		# printf "[%i] %-36s %-5s (%s)\n" "$i" "$file" "${port}" "enabled";
		let "i+=1"
	done
	for file in "${NGCTL_AVAILABLE}"*; do
		if [ ! -f "${file}" ]; then
			break
		fi
		cat "${file}" | while read line; do
			if [[ "$line" =~ listen ]]; then
				port="${line##listen }"
				port="${port%%;}"
				ports[$i-1]=$port
				break
			fi
		done
		# printf "[%i] %-36s %-5s (%s)\n" "$i" "$file" "${port}" "enabled";
		let "i+=1"
	done

	port=$DEFAULT_PORT
	while [[ " ${ports[*]} " =~ " ${port} " ]]; do
		let "port+=1"
	done
	echo ${port}
}


nginx_version() {
	return
}


nginx_safe_start() {
	# check if nginx is running, by checking for nginx.pid file contents
	# if not present run nginx
	if [ -f ${NGCTL_INSTALL}nginx.pid ]; then
		nginx -s stop
	fi
	if [ -f ${NGCTL_INSTALL}nginx.pid ]; then
		echo "Error: Could not stop nginx before relaunch!"
	else
		nginx
	fi
}


nginx_conf_is_valid() {

	local syntax_is_ok=0
	local test_is_ok=0
	local res=$((nginx -t) 2>&1)
	if [[ "${res}" =~ " syntax is ok" ]]; then
		syntax_is_ok=1
	fi
	if [[ "${res}" =~ " test is successful" ]]; then
		test_is_ok=1
	else
		test_is_ok=0
	fi

	# return 0 if all good, 1 otherwise
	if [ $test_is_ok -eq 0 ]; then
		echo "failure"
	else
		echo "success"
	fi
}


main() {

	case "$1" in

		"start" | "add" )
			local location=$(pwd)"/"
			local port=""

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

			file="ngctl${location////.}"
			file="${file::-1}"
			pe="${NGCTL_ENABLED}${file}"
			pa="${NGCTL_AVAILABLE}${file}"

			if [ -z $port ] && ( [ -f "${pa}" ] || [ -f "${pe}" ] ); then
				if [ -f "${pa}" ]; then
					mv "${pa}" "${pe}"
				fi
				port=$(ngctl_get_conf_port "${pe}")
			else
				if [ -n $port ]; then
					port=$(ngctl_find_port_available)
				fi
				printf "$template_text\n" $port "$location" > "$pe"
			fi

			nginx -t &>/dev/null
			nginx -s reload &>/dev/null
			printf "location enabled: %s\n" $location
			printf " --> http://localhost:%i/\n" $port
		;;


		"enable" )
			ngctl_print_confs "${NGCTL_AVAILABLE}" "disabled" 1
			read -p "Enter location number to enable: " option
			file="${servers_files[$option-1]##/*/}"
			mv "${NGCTL_AVAILABLE}${file}" "${NGCTL_ENABLED}${file}"
			nginx -s reload &>/dev/null
			local port=$(ngctl_get_conf_port "${NGCTL_ENABLED}${file}")
			local root=$(ngctl_get_conf_root "${NGCTL_ENABLED}${file}")
			printf " -> %-36s http://localhost:%-5s (enabled)\n" "${root}" "${port}"
		;;


		"disable" )
			ngctl_print_confs "${NGCTL_ENABLED}" "enabled" 1
			read -p "Enter location number to disable: " option
			file="${servers_files[$option-1]##/*/}"
			mv "${NGCTL_ENABLED}${file}" "${NGCTL_AVAILABLE}${file}"
			nginx -s reload &>/dev/null
			local port=$(ngctl_get_conf_port "${NGCTL_AVAILABLE}${file}")
			local root=$(ngctl_get_conf_root "${NGCTL_AVAILABLE}${file}")
			printf " -> %-36s http://localhost:%-5s (disabled)\n" "${root}" "${port}"
		;;


		"ls" )
			ngctl_print_confs "${NGCTL_ENABLED}" "enabled" 1
			ngctl_print_confs "${NGCTL_AVAILABLE}" "available" ${servers_idx}
		;;


		"status" )
			# Assumes active is line 3
			status="not implememented"
			printf 'nginx.service is %s\n' $status 
		;;


		"version" )
			ngx_version=$(nginx -V 2>&1 | head --lines=1 | awk '{print $3}' | awk -F '/' '{print $2}')
			awk_version=$(awk --version 2>&1 | head --lines=1 | awk '{print $2}')
			sites_enabled="not found"
			sites_available="not found"
			if [ -d $SITES_AVAILABLE ]; then
				sites_available="found"
			fi
			if [ -d "${NGCTL_ENABLED}" ]; then
				sites_enabled="found"
			fi
			printf "$version_template\n" $ngx_version $smd_version $awk_version $sites_available $sites_enabled
		;;


		"help" )
			printf '%s\n\n' "$help_template"
		;;


		* )
			printf '%s\n\n' "$help_template"
		;;

	esac
	exit 0
}

main $@