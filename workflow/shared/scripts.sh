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


function mysql_execute() {
    declare -A credentials
    eval credentials=("$(s2a "$1")")
    mysql \
        --host="${credentials[HOST]}" \
        --user="${credentials[USER]}" \
        --password="${credentials[PASS]}" \
        --port="${credentials[PORT]}"\
        "${credentials[NAME]}" \
        --execute="$2"
}

function mysql_import() {
    declare -A credentials
    eval credentials=("$(s2a "$1")")
    import_file="$2"
    mysql \
        --host="${credentials[HOST]}" \
        --user="${credentials[USER]}" \
        --password="${credentials[PASS]}" \
        --port="${credentials[PORT]}"\
        "${credentials[NAME]}" \
        < $import_file
}


function mysql_dump() {
    declare -A credentials
    eval credentials=("$(s2a "$1")")
    shift
    mysqldump \
        --host="${credentials[HOST]}" \
        --user="${credentials[USER]}" \
        --password="${credentials[PASS]}" \
        --post="${credentials[PORT]}"\
        "${credentials[NAME]}" \
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

#
# Capture MySQL credentials based on branch
#
function branch_credentials() {
    #
    # Uppercase CIRCLE_BRANCH
    # Dereference credentials to get value of credentials
    #
    echo "$(dereference "${CIRCLE_BRANCH^^}_CREDENTIALS")"
}

BRANCH_CREDENTIALS="$(branch_credentials)"
