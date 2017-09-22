#!/usr/bin/env bash
#
# workflow/shared/scripts.sh - Includes files for source
#

declare=${REPO_ROOT:=}
declare=${CIRCLE_BRANCH:=}
declare=${PROD_GIT_USER:=}
declare=${PROD_GIT_REPO:=}
declare=${QA_GIT_USER:=}
declare=${QA_GIT_REPO:=}
declare=${ARTIFACTS_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${TERMINUS_ROOT:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${ARTIFACTS_FILE:="${CIRCLE_ARTIFACTS}/shared-scripts.log"}"

#
# Set an error trap. Uses an $ACTION variable.
#
ACTION=""
announce () {
    ACTION="$1"
    printf "${ACTION}\n"
    printf "${ACTION}\n" >> $ARTIFACTS_FILE
}
onError() {
    if [ $? -ne 0 ] ; then
        printf "FAILED: ${ACTION}.\n"
        exit 1
    fi
}
trap onError ERR

#
# Making artifact subdirectory
#
announce "Creating artifact file ${ARTIFACTS_FILE}"
echo . > $ARTIFACTS_FILE
onError


# https://stackoverflow.com/a/12973694/102699
function trim {
    echo "$1" | xargs
}

MYSQL_ENV=""
function set_mysql_env() {
    MYSQL_ENV="$1"
    write_mysql_credentials "${MYSQL_ENV}"
}

function execute_mysql() {
    branch="${2:-${MYSQL_ENV}}"
    mysql --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" --execute="$1"
}

function import_mysql() {
    import_file="$1"
    branch="${2:-${MYSQL_ENV}}"
    mysql --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" < $import_file
}

function dump_mysql() {
    branch="$1"
    shift
    mysqldump --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" "$@"
}

#
# Output value of global variable given its name
#
function dereference() {
    #
    # Assign credentials var to $varname
    #
    varname="$1"
    echo "$(eval echo "\$${varname}")"
}

function execute_terminus() {
    ${TERMINUS_ROOT}/vendor/bin/terminus "$@"
}

#
# Define the MySQL defaults file
#
function get_mysql_defaults_file() {
    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi
    echo "${HOME}/mysql/${branch}-mysql.defaults"
}

#
# Get URL of website for a given branch
#
function get_website_url() {
    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi
    echo "http://${branch}-wabe.pantheonsite.io"
}

#
# Capture MySQL credentials given a branch
#
function write_mysql_credentials() {

    mkdir -p "${HOME}/mysql"
    cd "${HOME}/mysql"

    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi

    defaults_file="$(get_mysql_defaults_file "${branch}")"

    echo "[client]" > ${defaults_file}

    curl "$(get_website_url "${branch}")"

    credentials="$(execute_terminus connection:info "wabe.${branch}" --fields=* --format=yaml | grep mysql_ )"

    saveIFS="${IFS}"
    IFS=$'\n'

    assignments=""
    for credential in ${credentials}; do
        name="${credential%%:*}"
        value="$(trim "${credential#* }")"
        case "${name}" in
            mysql_host) property="host"
                ;;
            mysql_username) property="user"
                ;;
            mysql_password) property="password"
                ;;
            mysql_port) property="port"
                ;;
            mysql_database) property="database"
                ;;
            *) property=""
                ;;
        esac
        if [ "" != "${property}" ] ; then
            echo "${property}=\"${value}\"" >> ${defaults_file}
        fi
    done

    IFS="${saveIFS}"

}
