#!/usr/bin/env bash

declare=${PANTHEON_MACHINE_TOKEN:=}
declare=${REPO_ROOT:=}

# @link https://pantheon.io/docs/terminus

cd "{$HOME}"
if ! [ -d terminus ]; then
    mkdir -p terminus
    cd terminus

    # Install Terminus
    announce "Installing Terminus"
    curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install

    # Authenticate to Pantheon
    announce "Authenticating with Pantheon via machine token"
    execcute_terminus auth:login --machine-token="$(pantheon_machine_token)"

fi

announce "Setting alias to Pantheo's terminus"
alias terminus="{$HOME}/terminus/vendor/bin/terminus"