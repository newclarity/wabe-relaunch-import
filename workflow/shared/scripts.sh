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