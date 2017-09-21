#!/usr/bin/env bash

function s2a {
    a="$1"
    array=""
    for s in $a; do
        key="$(trim "${s%%=*}")"
        val="$(trim "${s##*=}")"
        array="["${key}"]="${val}" ${array}"
    done
    echo "${array}"
}

# https://stackoverflow.com/a/12973694/102699
function trim {
    echo "$1" | xargs
}

PREVIEW_CREDENTIALS="$(cat <<'EOH'
HOST=dbserver.preview.d5981687-a2b6-4a2c-9456-ae933c90b097.drush.in
USER=pantheon
PASS=5d2c4707db8b42f6900ad610d74ad362
PORT=16159
NAME=pantheon
EOH
)"

declare -A preview
eval preview=("$(s2a "${PREVIEW_CREDENTIALS}")")
echo "${preview[PORT]}"


