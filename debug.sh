#!/bin/bash

VERSION=0.1
DEFAULT_PORT=8080
SITES_ENABLED="/etc/nginx/sites-enabled/"
SITES_AVAILABLE="/etc/nginx/sites-available/"

declare -a servers_files
declare -i servers_idx=1
declare -a ports
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

ngctl_print_confs "${SITES_ENABLED}" "disabled" 1

for i in "${!servers_files[@]}"; do
    printf '%s\n' "${servers_files[i]}"
done