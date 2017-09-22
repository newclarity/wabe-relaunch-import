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


function execute_mysql() {
    declare -A "credentials=($1)"
    mysql \
        --host="${credentials["HOST"]}" \
        --user="${credentials["USER"]}" \
        --password="${credentials["PASS"]}" \
        --port="${credentials["PORT"]}"\
        "${credentials["NAME"]}" \
        --execute="$2"
}

function mysql_import() {
    declare -A "credentials=($1)"
    import_file="$2"
    mysql \
        --host="${credentials["HOST"]}" \
        --user="${credentials["USER"]}" \
        --password="${credentials["PASS"]}" \
        --port="${credentials["PORT"]}"\
        "${credentials["NAME"]}" \
        < $import_file
}


function mysql_dump() {
    declare -A "credentials=($1)"
    shift
    mysqldump \
        --host="${credentials["HOST"]}" \
        --user="${credentials["USER"]}" \
        --password="${credentials["PASS"]}" \
        --post="${credentials["PORT"]}"\
        "${credentials["NAME"]}" \
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
    ${REPO_ROOT}/vendor/bin/terminus "$@"
}

function pantheon_machine_token() {
    echo "$(cat "${REPO_ROOT}/files/pantheon-machine-token")"
}

#
# Capture MySQL credentials given a branch
#
function branch_mysql_credentials() {

    branch="$1"
    if [ "" == "${branch}" ]; then
        branch="${CIRCLE_BRANCH}"
    fi

    credentials="$(execute_terminus connection:info "wabe.${branch}" --fields=* | grep MySQL)"

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

