ENVIRONMENTS_DIR="${HOME}/.environments"
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

__env_main_path() {
        if [ -n "$1" ]; then
                __env_named "$1"; return $?
        fi

	__env_path_tree; return $?
}

__env_main_init() {
	EDITOR=${EDITOR:-vi}
	

	local _path="$(pwd)/${ENV_FILE}"
	__env_edit "$_path" || return $?
	
	if [ -n "${1}" ]; then
		local _link="${ENVIRONMENTS_DIR}/${1}"
		test -L "$_link" && rm "$_link"
		ln -s "$_path" "$_link"
	fi
	
}

__env_main_source() {
	local _path=$(__env_main_path "$@") || return $?
	pushd "$(dirname "$_path")" >/dev/null
	source "$_path"
	popd >/dev/null
}

__env_main_switch() {
	local _path=$(__env_main_path "$@") || return $?	
	cd "$(dirname "$_path")"
	source "$_path"
}


__env_help() {
	cat << EOF
Arguments:

[name]
	A named environment symlink found within ${ENVIRONMENTS_DIR}
	otherwise if not supplied then an environment file found with the current working directory or its parents.

Commands:

init [link]
	Create or edit an environment file within the current working directory.
	If one doesn't exist then it is created. 
	If [link] is supplied then a symlink is created in ${ENVIRONMENTS_DIR}

path [name]
	Get the path for an environment file

source [name]
	Source an environment file

switch [name]
	Source an evironment file and then switch to its parent directory

EOF
}


profile() {
	local _command=$1
	case $_command in
		"" | "-h" | "--help" )
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
