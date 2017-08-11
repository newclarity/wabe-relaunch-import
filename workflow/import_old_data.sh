#!/usr/bin/env bash

announce "Importing old posts..."
mysql -h ${TARGET_HOSTNAME} -e "INSERT INTO wp_posts (SELECT * FROM old_posts)" ${DB_NAME}

announce "Importing old post meta ..."
mysql -h ${TARGET_HOSTNAME} -e "INSERT INTO wp_postmeta (SELECT * FROM old_postmeta)" ${DB_NAME}

announce "Importing old terms..."
mysql -h ${TARGET_HOSTNAME} -e "INSERT INTO wp_terms (SELECT * FROM old_terms)" ${DB_NAME}

announce "Importing old term_taxonomy..."
mysql -h ${TARGET_HOSTNAME} -e "INSERT INTO wp_term_taxonomy (SELECT * FROM old_term_taxonomy)" ${DB_NAME}

announce "Importing old term relationships..."
mysql -h ${TARGET_HOSTNAME} -e "INSERT INTO wp_term_relationships (SELECT * FROM old_term_relationships)" ${DB_NAME}

# Get missing XML
announce "Retrieving story XML from NPR API..."
curl -L -k http://${TARGET_HOSTNAME}/npr-missing-story-xml

# Attribute/import authors for posts
announce "Processing authors from NPR API..."
curl -L -k http://${TARGET_HOSTNAME}/npr-import-authors

# Process photo attributions
announce "Processing image attributions from NPR API..."
curl -L -k http://${TARGET_HOSTNAME}/npr-image-attributions

# Process content source terms
announce "Setting Content Source taxonomy terms..."
curl -L -k http://${TARGET_HOSTNAME}/npr-content-sources
