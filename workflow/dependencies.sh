#!/usr/bin/env bash

declare=${WORKFLOW_ROOT:=}
declare=${SHARED_SCRIPTS:=}
declare=${INCLUDES_ROOT:=}

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