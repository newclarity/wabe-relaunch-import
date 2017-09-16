#!/usr/bin/env bash

declare=${PANTHEON_SITE_NAME:=}
declare=${WORKFLOW_ROOT:=}

source ${WORKFLOW_ROOT}/shared/scripts.sh

DB_HOSTNAME=dbserver.import.d5981687-a2b6-4a2c-9456-ae933c90b097.drush.in
DB_USERNAME=pantheon
DB_PASSWORD=ef4d5a6cfe564c0c84b86bfb7013d9d6
DB_PORT=11409
DB_NAME=pantheon
WWW_HOST=http://import-wabe.pantheonsite.io

# Clone the live database and files to the target environment
#announce "Cloning WABE live site database to import branch"
./vendor/bin/terminus env:clone-content --db-only -y ${PANTHEON_SITE_NAME}.live import

# Add some sanity checks here
announce "Preparing import data to assure no conflicting IDs...";
./vendor/bin/terminus wp wabe.import wabe-prepare-import

source ${WORKFLOW_ROOT}/includes/import_old_data.sh
