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


#
# Set the Git user and repo based on the branch
#
#case "${CIRCLE_BRANCH}" in
#    master)
#        GIT_USER="${PROD_GIT_USER}"
#        GIT_REPO="${PROD_GIT_REPO}"
#        ;;
#    qa)
#        GIT_USER="${QA_GIT_USER}"
#        GIT_REPO="${QA_GIT_REPO}"
#        ;;
#esac
#GIT_URL="${GIT_USER}@${GIT_REPO}"
#announce "Git branch is ${CIRCLE_BRANCH}; URL is ${GIT_URL}"

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
    mysql --defaults-extra-file="$(mysql_defaults_file "${branch}")" --execute="$1"
}

function import_mysql() {
    import_file="$1"
    branch="${2:-${MYSQL_ENV}}"
    mysql --defaults-extra-file="$(mysql_defaults_file "${branch}")" < $import_file
}

function dump_mysql() {
    branch="$1"
    shift
    mysqldump --defaults-extra-file="$(mysql_defaults_file "${branch}")" "$@"
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
function mysql_defaults_file() {
    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi
    echo "~/mysql/${branch}-mysql.defaults"
}

#
# Capture MySQL credentials given a branch
#
function write_mysql_credentials() {

    mkdir -p ~/mysql
    cd ~/mysql

    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi

    defaults_file="$(mysql_defaults_file "${branch}")"

    echo "[client]" > ${defaults_file}

    credentials="$(execute_terminus connection:info "wabe.${branch}" --fields=* | grep MySQL)"

    saveIFS="${IFS}"
    IFS=$'\n'

    assignments=""
    for credential in ${credentials}; do
        name="$(trim "${credential:8:10}")"
        value="$(trim "${credential:19}")"
        case "${name}" in
            Host) property="host"
                ;;
            Username) property="user"
                ;;
            Password) property="password"
                ;;
            Port) property="port"
                ;;
            Database) property="database"
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
