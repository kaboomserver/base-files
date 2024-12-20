#!/bin/sh

_EXEC_PATH="$(realpath .)"
_HAS_TTY=0
if (exec < /dev/tty) 2>/dev/null; then
    _HAS_TTY=1
fi

if [ "$DEBUG" = 1 ]; then
    debug() {
        printf '[DEBUG] '

        # If shell supports FUNCNAME, print it
        # The -20 is used to pad the function name with up to 20 spaces on the right.
        if [ -n "${FUNCNAME+x}" ]; then
            # shellcheck disable=SC3054 # FUNCNAME support requires array support
            printf '%-20s' "${FUNCNAME[1]}"
        fi

        echo "$@"
    }
else debug() { true; }
fi

contains() {
    NEEDLE="$1"
    shift

    for piece in "$@"; do
        if [ "$piece" = "$NEEDLE" ]; then
            return 0
        fi
    done

    return 1
}

check_path() {
    rpath="$(realpath "$1")"

    case "$1" in
        "/"*)   echo "Attempted path traversal: $1 is absolute"
                return 1;;
        *);; # Safe
    esac

    case "$rpath" in
        "$_EXEC_PATH/"*);; # Safe
        *)  echo "Attempted path traversal: $1 is outside current directory"
            return 1;;
    esac

    return 0
}

download() {
    debug "downloading $1 to $2"
    exitcode=0
    statuscode=0

    curl_params="-fL $1 -o $2 --write-out %{http_code}"

    # shellcheck disable=SC2086 # Intentional
    if [ $_HAS_TTY = 1 ]; then
        # TTY present: Enable curl's progress bar, clear it if operation successful
        tput sc 2>/dev/null || true # Save cursor pos

        statuscode=$(curl -# $curl_params </dev/tty 3>&1) || exitcode=$?
        if [ $exitcode = 0 ]; then
            (tput rc; tput ed) 2>/dev/null || true # Reset cursor pos; Clear to end
        fi
    else
        statuscode=$(curl $curl_params) || exitcode=$?
    fi

    if [ "$statuscode" = "404" ]; then
        return 100
    fi

    return $exitcode
}
