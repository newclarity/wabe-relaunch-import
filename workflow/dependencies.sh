#!/usr/bin/env bash

declare=${WORKFLOW_ROOT:=}
declare=${SHARED_SCRIPTS:=}
declare=${INCLUDES_ROOT:=}
declare=${CIRCLE_BRANCH:=}

#
# Ensure shared scripts are executable
#
echo "Make shared scripts ${SHARED_SCRIPTS} executable"
sudo chmod +x "${SHARED_SCRIPTS}"
echo "Make includes executable"
sudo chmod -R +x "${WORKFLOW_ROOT}/includes"

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"

#
# Install Pantheon's Terminus
#
source "${INCLUDES_ROOT}/terminus.sh"

#
# Set the default MySQL environment to be same as current branch
# Each branch should equate to an environment, at least on Pantheon
#
announce "Set default MySQL environment to ${CIRCLE_BRANCH}"
set_mysql_env "${CIRCLE_BRANCH}"

