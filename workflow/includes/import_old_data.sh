#!/usr/bin/env bash

function mysql_dest() {
    mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "$1" ${DB_NAME}
}

announce "Adding import tables to working database..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} ${DB_NAME} < import_package.sql

# Add some sanity checks here
announce "Preparing import data to assure no conflicting IDs...";
./vendor/bin/terminus wp ${PANTHEON_SITE_NAME}.import -- wabe-prepare-import

announce "Importing posts..."
mysql_dest "INSERT INTO wp_posts (SELECT * FROM import_posts)"

announce "Importing post meta ..."
mysql_dest "INSERT INTO wp_postmeta (SELECT * FROM import_postmeta)"

announce "Importing terms..."
mysql_dest "INSERT INTO wp_terms (SELECT * FROM import_terms)"

announce "Importing term_taxonomy..."
mysql_dest "INSERT INTO wp_term_taxonomy (SELECT * FROM import_term_taxonomy)"

announce "Importing term relationships..."
mysql_dest "INSERT INTO wp_term_relationships (SELECT * FROM import_term_relationships)"

announce "Importing posts into live tables..."
./vendor/bin/terminus wp wabe.import wabe-import

# Set the home page setting

# Set the theme settings

# Set the active theme
