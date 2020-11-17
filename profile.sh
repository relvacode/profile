# Profile Script
# (c) Jason Kingsbury 2020
#
# Create and manage environment profiles.
# Environments are files that can be sourced by the shell to load context specific environment variables
# or other forms of scripts associated with a given directory context.
#
# Contains methods for listing, editing and sourcing those environment contexts,
# as well as linking contexts to a global profile directory which can be referenced from anywhere on the filesystem.
#
# Installation:
#     Add `source <checkout_dir>/profile.sh` to your shell's login script
#     Run `profile` to see available options
#


# The path on the filesystem that defines the where links to named environment profiles are created
ENVIRONMENTS_DIR="${HOME}/.environments"

# The name of the environment file within its parent context
ENV_FILE=".env"

test -d "${ENVIRONMENTS_DIR}" || mkdir "${ENVIRONMENTS_DIR}"

__env_err() {
	if [ -t 2 ]; then
		echo -n '\e[91m' >&2
	fi
	
	echo $@ >&2

	if [ -t 2 ]; then
		echo -n '\e[0m' >&2
	fi
}

__env_named() {
	if [ -z "$1" ]; then
		__env_err "A profile name is required"
		return 1
	fi
		
	local _path="${ENVIRONMENTS_DIR}/${1}"
	
	if [ ! -L "${_path}" ]; then
		__env_err "Profile ${1} could not be found in ${ENVIRONMENTS_DIR}"
		return 2
	fi

	readlink "${_path}"
}


__env_path_tree() {
	search_path=$(pwd)
	
	while [[ "$search_path" != / ]]; do
		local env_path="$search_path/$ENV_FILE"
		if [ -f "$env_path" ]; then
			echo "$env_path"
			return 0
		fi
		
		search_path=$(dirname "$search_path")
	done

	__env_err "Could not find a ${ENV_FILE} within the current directory or any parent directories"
	return 2
}

__env_edit() {
	set -o localoptions -o localtraps
	local target="${1}"
	
	local temp_dir=$(mktemp -d)
	trap "rm -rf "$temp_dir"" EXIT

	local temp_path="$temp_dir/env.sh"	
	touch "$temp_path"

	if [ -f "$target" ]; then
		cp "$target" "$temp_path"
	fi

	EDITOR=${EDITOR:-vi}
	$EDITOR "$temp_path"
	RETCODE=$?

	if [ $RETCODE -ne 0 ]; then
		__env_err "Editor $EDITOR exited with exit code $RETCODE"
		return $RETCODE
	fi

	mv "$temp_path" "$target"
}

__env_source() {
	set -o localoptions
	set -o allexport
	
	source "${1}"
}

__env_main_path() {
        if [ -n "$1" ]; then
                __env_named "$1"; return $?
        fi

	__env_path_tree; return $?
}

__env_main_edit() {
	EDITOR=${EDITOR:-vi}
	

	local _path="$(pwd)/${ENV_FILE}"
	__env_edit "$_path" || return $?
	
	if [ -n "${1}" ]; then
		local _link="${ENVIRONMENTS_DIR}/${1}"
		test -L "$_link" && rm "$_link"
		ln -s "$_path" "$_link"
	fi
	
}

__env_main_ls() {
	for _profile in $(ls -1 "${ENVIRONMENTS_DIR}"); do
		echo "$(basename "${_profile}")\t$(readlink "${ENVIRONMENTS_DIR}/${_profile}")"
	done
}

__env_main_source() {
	_path=$(__env_main_path "$@") || return $?
	_cwd=$(pwd)

	cd "$(dirname "$_path")"
	__env_source "$_path"
	cd "$_cwd"
}

__env_main_switch() {
	_path=$(__env_main_path "$@") || return $?	
	
	cd "$(dirname "$_path")"
	__env_source "$_path"
}


__env_help() {
	cat << EOF
Arguments:

[name]
	A named environment symlink found within ${ENVIRONMENTS_DIR}
	otherwise if not supplied then an environment file found with the current working directory or its parents.

Commands:

ls
	List stored environment profiles within ${ENVIRONMENTS_DIR}

edit   [link]
	Create or edit an environment file within the current working directory.
	If one doesn't exist then it is created. 
	If [link] is supplied then a symlink is created in ${ENVIRONMENTS_DIR}.
	EDTIOR can be supplied as an environment variable to change the editor

path   [name]
	Get the path for an environment file

source [name]
	Source an environment file.
	Assignments are exported automatically.

switch [name]
	Source an evironment file and then switch to its parent directory

EOF
}


profile() {
	local _command=$1
	case $_command in
		"" | "help" )
			__env_help
			;;
	*)
		shift

		__env_main_$_command $@
		RETCODE=$?

		if [ $RETCODE = 127 ]; then
			__env_err "Invalid command $_command"
			__env_help
			return 1
		fi
		
		return $RETCODE
		;;
	esac	
					
}
