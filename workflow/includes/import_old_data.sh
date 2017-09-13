#!/usr/bin/env bash

#announce "Extracting compressed data..."
#bzip2 -dk sql/import_package.sql.bz2

announce "Adding import tables to working database..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} ${DB_NAME} < import_package.sql

announce "Importing posts..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_posts (SELECT * FROM import_posts)" ${DB_NAME}

announce "Importing post meta ..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_postmeta (SELECT * FROM import_postmeta)" ${DB_NAME}

announce "Importing terms..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_terms (SELECT * FROM import_terms)" ${DB_NAME}

announce "Importing term_taxonomy..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_term_taxonomy (SELECT * FROM import_term_taxonomy)" ${DB_NAME}

announce "Importing term relationships..."
mysql -h ${DB_HOSTNAME} -u ${DB_USERNAME} -p${DB_PASSWORD} -P ${DB_PORT} -e "INSERT INTO wp_term_relationships (SELECT * FROM import_term_relationships)" ${DB_NAME}

# Get missing XML
announce "Retrieving story XML from NPR API..."
echo ${WWW_HOST}/npr-missing-story-xml
curl -L -k ${WWW_HOST}/npr-missing-story-xml

# Attribute/import authors for posts
announce "Processing authors from NPR API..."
echo ${WWW_HOST}/npr-import-authors
curl -L -k ${WWW_HOST}/npr-import-authors

# Process photo attributions
announce "Processing image attributions from NPR API..."
echo ${WWW_HOST}/npr-image-attributions
curl -L -k ${WWW_HOST}/npr-image-attributions

# Process content source terms
#announce "Setting Content Source taxonomy terms..."
echo ${WWW_HOST}/npr-content-source
curl -L -k ${WWW_HOST}/npr-content-source
