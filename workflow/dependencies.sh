#!/usr/bin/env bash

#
# Ensure shared scripts are executable
#
echo "Make shared scripts ${SHARED_SCRIPTS} executable"
sudo chmod +x "${SHARED_SCRIPTS}"

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"
