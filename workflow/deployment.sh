#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${REPO_ROOT:=}


source "${SHARED_SCRIPTS}"


#
#
#
announce "Adding import tables to working database..."
mysql_import "$(branch_credentials)" import_package.sql

#
# Add some sanity checks here
#
announce "Preparing import data to assure no conflicting IDs...";
${REPO_ROOT}/vendor/bin/terminus wp wabe.import -- wabe-prepare-import

announce "Importing posts..."
mysql_exec "$(branch_credentials)" \
    "INSERT INTO wp_posts (SELECT * FROM import_posts)"

announce "Importing post meta ..."
mysql_exec "$(branch_credentials)" \
    "INSERT INTO wp_postmeta (SELECT * FROM import_postmeta)"

announce "Importing terms..."
mysql_exec "$(branch_credentials)" \
    "INSERT INTO wp_terms (SELECT * FROM import_terms)"

announce "Importing term_taxonomy..."
mysql_exec "$(branch_credentials)" \
    "INSERT INTO wp_term_taxonomy (SELECT * FROM import_term_taxonomy)"

announce "Importing term relationships..."
mysql_exec "$(branch_credentials)" \
    "INSERT INTO wp_term_relationships (SELECT * FROM import_term_relationships)"

announce "Importing posts into live tables..."
${REPO_ROOT}/vendor/bin/terminus wp wabe.import wabe-import

# Set the home page setting

# Set the theme settings

# Set the active theme