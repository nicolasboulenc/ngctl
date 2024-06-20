#!/bin/bash

# to fix


VERSION=0.1
DEBUG=1
PORT_BASE=8080
SITES_ENABLED="/etc/nginx/sites-enabled/"
SITES_AVAILABLE="/etc/nginx/sites-available/"

TEMPLATE_HTML="server {
    listen %s;
    root %s;
    location / {
        try_files \$uri \$uri/ =404;
    }
}"

TEMPLATE_VERSION="nsm version: $VERSION
  -> nginx version:	%s
  -> systemd version:	%s
  -> sites-available:	%s
  -> sites-enabled:	%s"

TEMPLATE_HELP="nsm start [path=.] [port=%i]
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
nsm version"


declare -a server_files=()
declare -i server_enabled_count=0


nsm_update_server_files() {

	local option=$1
	local enabled=0
	local available=0

	if [[ $option =~ "both" ]]; then
		enabled=1
		available=1
	fi
	if [[ $option =~ "enabled" ]]; then
		enabled=1
	fi
	if [[ $option =~ "available" ]]; then
		available=1
	fi

	server_enabled_count=0	
	if [[ $enabled -eq 1 ]]; then
		local t=$(ls -1 "${SITES_ENABLED}"nsm.* 2>/dev/null)
		local status=$?
		if [[ $status -eq 0 ]]; then
			while read file; do
				# for some reason we need to check this?
				if [[ -f "$file" ]]; then
					server_files+=("$file")
					let "server_enabled_count+=1"
				fi
			done <<< "$t"
		fi
	fi

	if [[ $available -eq 1 ]]; then
		local t=$(ls -1 "${SITES_AVAILABLE}"nsm.* 2>/dev/null)
		local status=$?
		if [[ $status -eq 0 ]]; then
			while read file; do
				# for some reason we need to check this?
				if [[ -f "$file" ]]; then
					server_files+=("$file")
				fi
			done <<< "$t"
		fi
	fi

	# debug
	# printf "%s\n" "${server_files[*]}"
	# printf "enabled sites: %i\n" "${server_enabled_count}"
}


nsm_print_server_confs() {
	i=1
	d="enabled"
	for file in "${server_files[@]}"; do
		fc="$(<$file)"
		port=$(nsm_get_port "$fc")
		root=$(nsm_get_root "$fc")
		if [[ $i -eq $server_enabled_count+1 ]]; then
			d="available"
		fi
		printf "[%i] %-48s http://localhost:%-15s (%s)\n" "$i" "${root}" "${port}" "${d}";
		let "i+=1"
	done
}


nsm_parse_port() {

	local line=$1
	port="${line##listen}"
	port="${port##*]}"
	port="${port##*:}"
	port="${port%%;}"
	port="${port#* }"
	port="${port%* }"
	port="${port/default_server/}"
	port="${port/ssl/}"
	printf "%s" "$port"
}


nsm_parse_root() {

	local line=$1
	root="${line##root* }"
	root="${root%%;}"
	printf "%s" "$root"
}


# get port from site config file
nsm_get_port() {

	local content="$1"
	local port=""

	while read line; do
		if [[ "$line" =~ listen ]]; then
			port=$(nsm_parse_port "$line")
			printf "%s" "$port"
			return
		fi
	done <<< "$content"
}


# get root from site config file
nsm_get_root() {

	local content="$1"
	local root=""

	while read line; do
		if [[ "$line" =~ root ]]; then
			root=$(nsm_parse_root "$line")
			printf "%s" "$root"
			return
		fi
	done <<< "$content"
}


nsm_ports_get_available() {

	local ports=()

	local t=$(ls -1 "${SITES_ENABLED}"* 2>/dev/null)
	local status=$?
	if [[ $status -eq 0 ]]; then
		while read file; do
			# for some reason we need to check this?
			if [[ -f "$file" ]]; then
				while read line; do
					if [[ "$line" =~ listen ]]; then
						port=$(nsm_parse_port "$line")
						ports+=($port)
						break
					fi
				done < "$file"
			fi
		done <<< "$t"
	fi
	# [ $DEBUG -eq 1 ] && printf "Debug: ports used = %s\n" "${ports[*]}"

	local t=$(ls -1 "${SITES_AVAILABLE}"* 2>/dev/null)
	local status=$?
	if [[ $status -eq 0 ]]; then
		while read file; do
			# for some reason we need to check this?
			if [[ -f "$file" ]]; then
				while read line; do
					if [[ "$line" =~ listen ]]; then
						port=$(nsm_parse_port "$line")
						ports+=($port)
						break
					fi
				done < "$file"
			fi
		done <<< "$t"
	fi
	# [ $DEBUG -eq 1 ] && printf "Debug: ports used = %s\n" "${ports[*]}"

	port=$PORT_BASE
	while [[ " ${ports[*]} " =~ " ${port} " ]]; do
		let "port+=1"
	done

	echo $port
}


nsm_start() {

	path=$(pwd)"/"
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
				path=$(pwd)"/"
				popd >/dev/null 2>&1
			else
				printf "Error: path does not exist!"
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

	fn="nsm${path////.}"
	fn="${fn::-1}"
	pe="$SITES_ENABLED$fn"
	pa="$SITES_AVAILABLE$fn"

	if [ -z $port ] && ( [ -f $pa ] || [ -f $pe ] ); then
		# existing file
		[ $DEBUG -eq 1 ] && printf "%s\n" "Debug: Using existing file."
		if [ -f $pa ]; then
			mv "$pa" "$pe"
		fi
		fc="$(<$pe)"
		port=$( nsm_get_port "$fc")
	else
		# new file
		[ $DEBUG -eq 1 ] && printf "%s\n" "Debug: Creating new file."
		if [ -n $port ]; then
			port=$(nsm_ports_get_available)
		fi
		printf "$TEMPLATE_HTML\n" $port "$path" > "$pe"
	fi

	systemctl restart nginx.service
	printf "\nsite enabled: %s\n" $path
	printf " --> http://localhost:%s/\n" $port
}


nsm_remove() {

	nsm_update_server_files "both"
	nsm_print_server_confs
	read -p "Enter site number to remove: " option
	if [[ -f "${server_files[$option-1]}" ]]; then
		fc="$(<${server_files[$option-1]})"
		root=$(nsm_get_root "$fc")
		sudo rm "${server_files[$option-1]}"
		printf " -> %-36s (removed)\n" "${root}"
	else 
		printf "%s\n" "Error: Invalid option? Not a file?"
	fi
}


nsm_enable() {

	nsm_update_server_files "available"
	nsm_print_server_confs
	if [[ "${#server_files[@]}" -eq 0 ]]; then
		printf "%s\n" "Nothing to enable."
		return
	fi
	read -p "Enter site number to enable: " option
	file="${server_files[$option-1]##/*/}"
	if [[ -f "${SITES_AVAILABLE}${file}" && -d "${SITES_ENABLED}" ]]; then
		mv "${SITES_AVAILABLE}${file}" "${SITES_ENABLED}"
		systemctl restart nginx.service
		fc="$(<${SITES_ENABLED}${file})"
		port=$(nsm_get_port "$fc")
		root=$(nsm_get_root "$fc")
		printf " -> %-36s http://localhost:%-5s (enabled)\n" "${root}" "${port}"
	else 
		printf "%s\n" "Error: Invalid option, source not a file or destination not a directory!"
	fi
}


nsm_disable() {

	nsm_update_server_files "enabled"
	nsm_print_server_confs
	if [[ "${#server_files[@]}" -eq 0 ]]; then
		printf "%s\n" "Nothing to disable."
		return
	fi
	read -p "Enter site number to disable: " option
	file="${server_files[$option-1]##/*/}"
	if [[ -f "${SITES_ENABLED}${file}" && -d "${SITES_AVAILABLE}" ]]; then
		mv "${SITES_ENABLED}${file}" "${SITES_AVAILABLE}"
		systemctl restart nginx.service
		fc="$(<${SITES_AVAILABLE}${file})"
		port=$(nsm_get_port "$fc")
		root=$(nsm_get_root "$fc")
		printf " -> %-36s http://localhost:%-5s (disabled)\n" "${root}" "${port}"
	else 
		printf "%s\n" "Error: Invalid option, source not a file or destination not a directory!"
	fi	
}


nsm_ls() {
	nsm_update_server_files "both"
	nsm_print_server_confs
}


nsm_status() {
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
}


nsm_version() {

	local ngx_version=""
	local t=$(nginx -V  2>&1)
	while read line; do
		if [[ "$line" =~ version: ]]; then
			ngx_version="${line##*version:}"
			ngx_version="${ngx_version## nginx/}"
			ngx_version="${ngx_version%% (*}"
			break
		fi		
	done <<< "$t"

	local smd_version=""
	local t=$(systemctl --version 2>&1)
	while read line; do
		if [[ "$line" =~ systemd ]]; then
			smd_version="${line##*(}"
			smd_version="${smd_version%%)*}"
			break
		fi		
	done <<< "$t"

	sites_enabled="not found"
	sites_available="not found"
	if [ -d $SITES_AVAILABLE ]; then
		sites_available="found"
	fi
	if [ -d $SITES_ENABLED ]; then
		sites_enabled="found"
	fi
	printf "$TEMPLATE_VERSION\n" $ngx_version $smd_version $sites_available $sites_enabled
}


nsm_main() {

	case "$1" in

		"start" )
			nsm_start "$@" ;;

		"remove" )
			nsm_remove ;;

		"enable" )
			nsm_enable ;;

		"disable" )
			nsm_disable ;;

		"ls" )
			nsm_ls ;;

		"status" )
			nsm_status ;;

		"version" )
			nsm_version ;;

	"help" )
			printf '%s\n' "$TEMPLATE_HELP" ;;

		* )
			echo "Try 'nsm.sh help' for more information." ;;

	esac
}


nsm_main "$@"