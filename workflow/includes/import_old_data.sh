#!/usr/bin/env bash

announce "Extracting compressed data..."
bzip2 -dk sql/import_package.sql.bz2

announce "Adding old tables to working database..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} ${DB_NAME} < ${DATA_DIRECTORY:=sql}/import_package.sql

#announce "Importing old posts..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_posts (SELECT * FROM old_posts)" ${DB_NAME}

#announce "Importing old post meta ..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_postmeta (SELECT * FROM old_postmeta)" ${DB_NAME}

#announce "Importing old terms..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_terms (SELECT * FROM old_terms)" ${DB_NAME}

#announce "Importing old term_taxonomy..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_term_taxonomy (SELECT * FROM old_term_taxonomy)" ${DB_NAME}

#announce "Importing old term relationships..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_term_relationships (SELECT * FROM old_term_relationships)" ${DB_NAME}

# Get missing XML
#announce "Retrieving story XML from NPR API..."
#curl -L -k http://${WWW_HOST}/npr-missing-story-xml

# Attribute/import authors for posts
#announce "Processing authors from NPR API..."
#curl -L -k http://${WWW_HOST}/npr-import-authors

# Process photo attributions
#announce "Processing image attributions from NPR API..."
#curl -L -k http://${WWW_HOST}/npr-image-attributions

# Process content source terms
#announce "Setting Content Source taxonomy terms..."
#curl -L -k http://${WWW_HOST}/npr-content-sources
