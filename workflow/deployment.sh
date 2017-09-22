#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${REPO_ROOT:=}


source "${SHARED_SCRIPTS}"


#
#
#
announce "Adding import tables to working database..."
import_mysql import_package.sql "${CIRCLE_BRANCH}"

#
# Add some sanity checks here
#
announce "Preparing import data to assure no conflicting IDs...";
execute_terminus wp wabe.import -- wabe-prepare-import

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
execute_terminus wp wabe.import wabe-import

# Set the home page setting

# Set the theme settings

# Set the active theme