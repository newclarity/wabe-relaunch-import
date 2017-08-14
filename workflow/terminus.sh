#!/usr/bin/env bash

# @link https://pantheon.io/docs/terminus

# Install Terminus
curl -O https://raw.githubusercontent.com/pantheon-systems/terminus-installer/master/builds/installer.phar && php installer.phar install

# Authenticate to Pantheon
./vendor/bin/terminus auth:login --machine-token=${PANTHEON_MACHINE_TOKEN}

# Clone the live database to the target environment
./vendor/bin/terminus env:clone-content --db-only ${PANTHEON_SITE_NAME}.live preview