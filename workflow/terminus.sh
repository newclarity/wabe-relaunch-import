#!/usr/bin/env bash

# @link https://pantheon.io/docs/terminus

source shared/scripts.sh

# Install Terminus
announce "Installing Terminus"
curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install
alias terminus=/home/ubuntu/wabe-relaunch-import/vendor/bin/terminus

# Authenticate to Pantheon
announce "Authenticating with Pantheon via machine token"
terminus auth:login --machine-token=${PANTHEON_MACHINE_TOKEN}
