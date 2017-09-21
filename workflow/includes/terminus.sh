#!/usr/bin/env bash

declare=${PANTHEON_MACHINE_TOKEN:=}
declare=${REPO_ROOT:=}

# @link https://pantheon.io/docs/terminus

# Install Terminus
announce "Installing Terminus"
curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install

# Authenticate to Pantheon
announce "Authenticating with Pantheon via machine token"
${REPO_ROOT}/vendor/bin/terminus auth:login --machine-token=${PANTHEON_MACHINE_TOKEN}
