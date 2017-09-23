#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${REPO_ROOT:=}
declare=${IMPORT_PACKAGE_FILE:=}

source "${SHARED_SCRIPTS}"

DEPLOY_BRANCH="${CIRCLE_BRANCH}"

announce "Set default MySQL environment to ${DEPLOY_BRANCH}"
set_mysql_env "${DEPLOY_BRANCH}"

if [ "master" != "${DEPLOY_BRANCH}" ]; then
    announce "Cloning database from production to ${DEPLOY_BRANCH}."
    execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --db-only --no-interaction --yes

    announce "Cloning upload files from production to ${DEPLOY_BRANCH}."
    execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --files-only --no-interaction --yes
fi

announce "Adding import tables to working database..."
import_mysql "${DEPLOY_BRANCH}" < ${IMPORT_PACKAGE_FILE}

#
# Add some sanity checks here
#
#announce "Preparing import data to assure no conflicting IDs...";
#execute_terminus wp "wabe.${DEPLOY_BRANCH}" -- wabe-prepare-import

announce "Importing posts..."
execute_mysql "INSERT INTO wp_posts (SELECT * FROM import_posts)"

announce "Importing post meta ..."
execute_mysql "INSERT INTO wp_postmeta (SELECT * FROM import_postmeta)"

announce "Importing terms..."
execute_mysql "INSERT INTO wp_terms (SELECT * FROM import_terms)"

announce "Importing term_taxonomy..."
execute_mysql "INSERT INTO wp_term_taxonomy (SELECT * FROM import_term_taxonomy)"

announce "Importing term relationships..."
execute_mysql "INSERT INTO wp_term_relationships (SELECT * FROM import_term_relationships)"

announce "Importing posts into live tables..."
execute_terminus wp "wabe.${DEPLOY_BRANCH}" wabe-import

# Set the home page setting

# Set the theme settings

# Set the active theme