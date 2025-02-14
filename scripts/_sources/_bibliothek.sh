#!/bin/sh
# Bibliothek is Paper's API for downloading builds
# https://docs.papermc.io/misc/downloads-api

_fetch_latest_build() {
    builds_url="$1/builds"

    debug "fetch: $builds_url"
    BUILD_JSON="$(fetch -so- "$builds_url")"

    # We have to read the variables like this because POSIX read
    # doesn't support reading multiple variables at a time
    for var in LATEST_BUILD LATEST_BUILD_FILENAME; do
        read -r "${var?}"
    done <<FETCH_LATEST_BUILD_HEREDOC
$(echo "$BUILD_JSON" \
    | jq --raw-output --exit-status '.builds[-1] | "\(.build)\n\(.downloads?.application?.name)"')
FETCH_LATEST_BUILD_HEREDOC
}

_download_type_bibliothek() {
    read_args endpoint project version
    require_args endpoint project version
    project_url="${arg_endpoint:?}/v2/projects/${arg_project:?}/versions/${arg_version:?}"

    _fetch_latest_build "$project_url"
    debug "latest file: $LATEST_BUILD_FILENAME ($LATEST_BUILD)"

    download_url="$project_url/builds/$LATEST_BUILD/downloads/$LATEST_BUILD_FILENAME"
    download "$download_url" "$1"
}