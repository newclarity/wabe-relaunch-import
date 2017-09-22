#!/usr/bin/env bash

declare=${PANTHEON_MACHINE_TOKEN:=}

# @link https://pantheon.io/docs/terminus

cd ~/
if ! [ -d terminus ]; then
    mkdir -p terminus
    cd terminus

    # Install Terminus
    announce "Installing Terminus"
    curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install

    # Authenticate to Pantheon
    announce "Authenticating with Pantheon via machine token"
    execute_terminus auth:login --machine-token="${PANTHEON_MACHINE_TOKEN}"

fi
announce "Setting alias to Pantheon's Terminus CLI"
alias terminus=~/terminus/vendor/bin/terminus