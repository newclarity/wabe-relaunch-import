#!/usr/bin/env bash


    REPO_ROOT="/vagrant/relaunch-import/"

    CIRCLE_BRANCH="preview"

declare=${MYSQL_CREDENTIALS:=}

# https://stackoverflow.com/a/12973694/102699
function trim {
    echo "$1" | xargs
}

function execute_terminus() {
    /usr/local/bin/terminus/vendor/bin/terminus "$@"
}

function execute_mysql() {
    declare -A credentials
    eval credentials=("$(s2a "$1")")
    mysql \
        --host="${credentials["HOST"]}" \
        --user="${credentials["USER"]}" \
        --password="${credentials["PASS"]}" \
        --port="${credentials["PORT"]}"\
        "${credentials["NAME"]}" \
        --execute="$2"
}

#
# Capture MySQL credentials based on branch
#
function get_branch_mysql_credentials() {

    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi

    array_name="$2"
    if [ "" == "${array_name}" ]; then
        array_name="MYSQL_CREDENTIALS"
    fi

    credentials="$(execute_terminus connection:info "wabe.${branch}" --fields=*| grep MySQL)"

    saveIFS="${IFS}"
    IFS=$'\n'

    assignments=""
    for credential in ${credentials}; do
        name="$(trim "${credential:8:10}")"
        value="$(trim "${credential:19}")"
        case "${name}" in
            Command) element="CMD"
                ;;
            Host) element="HOST"
                ;;
            Username) element="USER"
                ;;
            Password) element="PASS"
                ;;
            URL) element="URL"
                ;;
            Port) element="PORT"
                ;;
            Database) element="NAME"
                ;;
        esac

        assignments="${assignments} [${element}]=\"${value}\""
    done

    echo "${assignments}"

    IFS="${saveIFS}"

}


function showem {
    declare -A "CREDS=($1)"
    echo "${CREDS["HOST"]}"
    echo "${CREDS["PASS"]}"
    echo "${CREDS["NAME"]}"
}

creds="$(get_branch_mysql_credentials live)"

showem "${creds}"


#
#declare -A "CREDS2=($(get_branch_mysql_credentials live))"
#assignment="$(get_branch_mysql_credentials preview)"
#declare -A "CREDS=(${assignment})"
#
#echo "${CREDS["HOST"]}"
#echo "${CREDS["PASS"]}"
#echo "${CREDS["NAME"]}"

