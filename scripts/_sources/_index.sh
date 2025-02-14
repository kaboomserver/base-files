#!/bin/sh
# shellcheck disable=SC1091

. "$_SCRIPT_PATH"/_sources/_bibliothek.sh
. "$_SCRIPT_PATH"/_sources/_url.sh
. "$_SCRIPT_PATH"/_sources/_zip.sh

_parse_args() {
    # <- { "a": "b", "c": "d" }
    # -> a
    # -> b
    # -> c
    # -> d
    jq --raw-output --exit-status \
        'to_entries[] | "\(.key)\n\(.value)"'
}

read_args() {
    while read -r key; read -r value; do
        debug "read: $key=$value"

        if contains "$key" "$@"; then
            debug "set: arg_$key"

            # The eval here might look scary, but we know that $key
            # is safe and we escape $value.
            eval "arg_$key=\$value"
        fi
    done <<PARSE_ARGS_HEREDOC # We must use a heredoc here, see shellcheck SC2031
$(_parse_args)
PARSE_ARGS_HEREDOC
}

require_args() {
    for key in "$@"; do
        # Same thing as above
        eval "tmp=\$arg_$key"
        if [ -z "$tmp" ]; then
            echo "Missing required download argument $key"
            return 1
        fi

        tmp=""
    done
}

download_with_args() {
    require_args url

    # Unfortunately we cannot handle skip_404 here as "zip" can't
    # continue if we 404
    download "${arg_url:?}" "$1"
}
 
download_type() {
    # Calling the function with _download_type_"$1" opens up the
    # possibility for users to run arbitrary commands, so we must
    # manually handle the type.
    #
    # Since the args are part of the function's stdin, they will be
    # be propagated into the _download_type_... functions.
    case "$1" in
        "bibliothek")   _download_type_bibliothek "$2";;
        "url")          _download_type_url "$2";;
        "zip")          _download_type_zip "$2";;
        *) echo Invalid download type "$1"
           return 1;;
    esac
}
