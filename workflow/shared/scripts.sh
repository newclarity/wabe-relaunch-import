#!/usr/bin/env bash
#
# workflow/shared/scripts.sh - Includes files for source
#

declare=${CIRCLE_BRANCH:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${TERMINUS_ROOT:=}
declare=${PANTHEON_SITE_NAME:=}

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

MYSQL_ENV=""

# https://stackoverflow.com/a/12973694/102699
function trim {
    echo "$1" | xargs
}

function execute_mysql() {
    branch="${2:-${MYSQL_ENV}}"
    wakeup_website "${branch}"
    mysql --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" --execute="$1"
}

function import_mysql() {
    import_file="$1"
    branch="${2:-${MYSQL_ENV}}"
    wakeup_website "${branch}"
    mysql --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" < $import_file
}

function dump_mysql() {
    branch="$1"
    set_mysql_env "${branch}"
    wakeup_website "${branch}"
    shift
    mysqldump \
        --defaults-extra-file="$(get_mysql_defaults_file "${branch}")" \
        "$(get_database_name "${branch}")" \
        "$@"
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
    wakeup_website "$(get_mysql_env "")"
    ${TERMINUS_ROOT}/vendor/bin/terminus "$@"
}

#
# Define the MySQL defaults file
#
function get_database_name() {
    branch="$(get_mysql_env "$1")"
    defaults_file="$(get_mysql_defaults_file "${branch}")"
    database="$(cat "${defaults_file}" | grep "database=")"
    echo "${database#*=}"
}

function get_mysql_env() {
    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${MYSQL_ENV}"
    fi
    echo "${branch}"
}

#
# Define the MySQL defaults file
#
function get_mysql_defaults_file() {
    branch="$(get_mysql_env "$1")"
    echo "${HOME}/mysql/${branch}-mysql.defaults"
}

#
# Get URL of website for a given branch
#
function get_website_url() {
    branch="$(get_mysql_env "$1")"
    echo "http://${branch}-${PANTHEON_SITE_NAME}.pantheonsite.io"
}

#
# Wakeup the website database by requesting a lightweight URL: robots.txt
#
function wakeup_website() {
    branch="$(get_mysql_env "$1")"
    url="$(get_website_url "$1")/robots.txt"
    curl "${url}" 2>&1 /dev/null  
}

#
# Capture MySQL credentials given a branch
#
function write_mysql_credentials() {

    save_dir="$(pwd)"

    mkdir -p "${HOME}/mysql"
    cd "${HOME}/mysql"

    branch="$(get_mysql_env "$1")"

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
            mysql_database)
                property=""
                database="${value}"
                ;;
            *) property=""
                ;;
        esac
        if [ "" != "${property}" ] ; then
            echo "${property}=${value}" >> ${defaults_file}
        fi
    done
    echo "[mysql]" >> ${defaults_file}
    echo "database=${database}" >> ${defaults_file}

    IFS="${saveIFS}"

    cd "${save_dir}"

}

#
# Takes a space separated string and "quotes" it for MySQL "IN" clause, e.g.
#
#       foo bar baz
#
# becomes:
#
#       'foo','bar','baz'
#
#
function quote_mysql_set() {
    echo "'$(echo $1 | sed "s/ /','/g")'"
}

#
# Sets the global MYSQL_ENV to a passed branch name, and
# Creates a --defaults-extra-file in my.cnf format based
# credentials provided by Pantheon's terminus command
#
function set_mysql_env() {
    MYSQL_ENV="$1"
    announce "Set default MySQL environment to ${MYSQL_ENV}"
    write_mysql_credentials "${MYSQL_ENV}"
}

#
# Set the default MySQL environment to be same as current branch
# Each branch should equate to an environment, at least on Pantheon
#
set_mysql_env "${CIRCLE_BRANCH}"


