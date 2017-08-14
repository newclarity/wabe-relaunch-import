#!/usr/bin/env bash

source shared/scripts.sh

TARGET_HOSTNAME=dbserver.preview.d5981687-a2b6-4a2c-9456-ae933c90b097.drush.in
DB_USERNAME=pantheon
DB_PASSWORD=5d2c4707db8b42f6900ad610d74ad362
DB_PORT=16159

# Clone the live database and files to the target environment
announce "Cloning WABE live site database and files to preview branch"
./vendor/bin/terminus env:clone-content -y ${PANTHEON_SITE_NAME}.live preview

source includes/import_old_data.sh