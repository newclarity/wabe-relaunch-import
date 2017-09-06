#!/usr/bin/env bash

declare=${PANTHEON_SITE_NAME:=}
declare=${WORKFLOW_ROOT:=}

source ${WORKFLOW_ROUTE}/shared/scripts.sh

DB_HOSTNAME=dbserver.preview.d5981687-a2b6-4a2c-9456-ae933c90b097.drush.in
DB_USERNAME=pantheon
DB_PASSWORD=5d2c4707db8b42f6900ad610d74ad362
DB_PORT=16159
DB_NAME=pantheon
WWW_HOST=http://preview-wabe.pantheonsite.io

# Clone the live database and files to the target environment
announce "Cloning WABE live site database and files to preview branch"
./vendor/bin/terminus env:clone-content --db-only -y ${PANTHEON_SITE_NAME}.live preview

source ${WORKFLOW_ROOT}/includes/import_old_data.sh