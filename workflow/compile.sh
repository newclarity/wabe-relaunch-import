#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}

declare=${STARTING_POST_ID:=}
declare=${ENDING_POST_DATE:=}

declare=${POST_TYPES:=}
declare=${STARTING_TERM_ID:=}

source ${SHARED_SCRIPTS}


#
# This is due to a strange behavior where using the '*' in
# the SQL would expand into a listing of directory contents
#
POST_FIELDS="ID, post_author, post_date, post_date_gmt, post_content, post_title,
    post_excerpt, post_status, comment_status, ping_status, post_password, post_name,
    to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent,
    guid, menu_order, post_type, post_mime_type, comment_count"

exit 1

preview_credentials="$(branch_mysql_credentials preview)"

# Add old stories
announce "Drop existing import posts table on 'preview'"
execute_mysql "${preview_credentials}" \
    "DROP TABLE IF EXISTS import_posts"

announce "Create import posts table on 'preview'"
execute_mysql "${preview_credentials}" \
    "CREATE TABLE import_posts LIKE wp_posts"

announce "Preparing old stories on 'preview'"
execute_mysql "${preview_credentials}" \
    "INSERT INTO import_posts (
        SELECT
            ${POST_FIELDS}
        FROM
            wp_posts
        WHERE 1=1
            AND post_type = 'post'
            AND post_status IN ( 'publish', 'private', 'draft' )
            AND post_date < '${ENDING_POST_DATE}'
            AND ID >= ${STARTING_POST_ID}
    )"

# Add other post types
for POST_TYPE in $POST_TYPES; do
    announce "Preparing ${POST_TYPE}s on 'preview'"
    execute_mysql "${preview_credentials}" \
        "INSERT INTO import_posts (
            SELECT
                ${POST_FIELDS}
            FROM
                wp_posts
            WHERE 1=1
                AND post_status = 'publish'
                AND post_type = '${POST_TYPE}'
        )"
done

# Prepare all necessary attachments for our posts that will be  imported
announce "Preparing attachments on 'preview'"
execute_mysql "${preview_credentials}" \
    "INSERT INTO import_posts (
        SELECT
            ${POST_FIELDS}
        FROM
            wp_posts
        WHERE 1=1
            AND post_type = 'attachment'
            AND post_parent IN ( SELECT ID FROM import_posts )
    )"


announce "Dropping existing import meta table on 'preview'"
execute_mysql "${preview_credentials}" \
    "DROP TABLE IF EXISTS import_postmeta;"

announce "Creating import meta table on 'preview'"
execute_mysql "${preview_credentials}" \
    "CREATE TABLE import_postmeta LIKE wp_postmeta;"

announce "Preparing post meta on 'preview'"
execute_mysql "${preview_credentials}" \
    "INSERT INTO import_postmeta (
        SELECT
            *
        FROM
            wp_postmeta
        WHERE
            post_id IN ( SELECT ID FROM import_posts )
        OR
            meta_key IN (
                'npr_author_xml',
                'npr_story_xml',
                '_wabe_story_authors',
                '_wabe_attribution_processed',
                '_wabe_authors_imported_from_xml',
                '_wabe_photo_agency',
                '_wabe_photo_agency_url',
                '_wabe_photo_credit',
                '_wabe_photo_npr_image_id'
            )
    )"

announce "Drop existing import terms table on 'preview'"
execute_mysql "${preview_credentials}" \
    "DROP TABLE IF EXISTS import_terms;"

announce "Preparing terms on 'preview'"
execute_mysql "${preview_credentials}" \
    "CREATE TABLE import_terms LIKE wp_terms;
        INSERT INTO import_terms (
            SELECT * FROM wp_terms WHERE term_id >= ${STARTING_TERM_ID}
        )"

announce "Drop existing import term taxonomy table on 'preview'"
execute_mysql "${preview_credentials}" \
    "DROP TABLE IF EXISTS import_term_taxonomy;"

announce "Create import term taxonomies table on 'preview'"
execute_mysql "${preview_credentials}" \
    "CREATE TABLE import_term_taxonomy LIKE wp_term_taxonomy;"

announce "Preparing term taxonomies on 'preview'"
execute_mysql "${preview_credentials}" \
    "INSERT INTO import_term_taxonomy (
        SELECT * FROM wp_term_taxonomy WHERE term_taxonomy_id >= ${STARTING_TERM_ID}
    )"

announce "Drop existing import term relationships table on 'preview'"
execute_mysql "${preview_credentials}" \
    "DROP TABLE IF EXISTS import_term_relationships;"

announce "Preparing term relationships on 'preview'"
execute_mysql "${preview_credentials}" \
    "CREATE TABLE import_term_relationships AS
        SELECT
            *
        FROM
            wp_term_relationships
        WHERE
            term_taxonomy_id >= ${STARTING_TERM_ID}
        OR
            object_id IN ( SELECT ID FROM import_posts )"

# Add Home page configs? OR is this referring to setting the WP "Reading Settings First Page Displays" option?

# Export the package
announce "Downloading import data package from 'preview'"
mysql_dump \
    "${preview_credentials}" \
    "import_posts" \
    "import_postmeta" \
    "import_terms" \
    "import_term_taxonomy" \
    "import_term_relationships" \
    > import_package.sql
