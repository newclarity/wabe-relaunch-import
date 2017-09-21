#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}

declare=${OLD_STORY_START_ID:=}
declare=${OLD_STORY_END_ID:=}
declare=${OLD_STORY_END_DATE:=}

declare=${POST_TYPES:=}
declare=${NEW_META_START_ID:=}
declare=${TERM_ID_START:=}

declare=${IMPORT_POSTS:=}
declare=${IMPORT_META:=}
declare=${IMPORT_TERMS:=}
declare=${IMPORT_TT:=}
declare=${IMPORT_TR:=}

declare=${SOURCE_POSTS:=}
declare=${SOURCE_META:=}
declare=${SOURCE_TERMS:=}
declare=${SOURCE_TT:=}
declare=${SOURCE_TR:=}

declare=${PREVIEW_CREDENTIALS:=}

source ${SHARED_SCRIPTS}


#
# This is due to a strange behavior where using the '*' in
# the SQL would expand into a listing of directory contents
#
POST_FIELDS="ID, post_author, post_date, post_date_gmt, post_content, post_title,
    post_excerpt, post_status, comment_status, ping_status, post_password, post_name,
    to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent,
    guid, menu_order, post_type, post_mime_type, comment_count"


# Add old stories
announce "Drop existing import posts table"
mysql_execute "$(branch_credentials)" \
    "DROP TABLE IF EXISTS ${IMPORT_POSTS}"

announce "Create import posts table"
mysql_execute "$(branch_credentials)" \
    "CREATE TABLE ${IMPORT_POSTS} LIKE ${SOURCE_POSTS}"

announce "Preparing old stories"
mysql_execute "$(branch_credentials)" \
    "INSERT INTO ${IMPORT_POSTS} (
        SELECT
            ${POST_FIELDS}
        FROM
            ${SOURCE_POSTS}
        WHERE 1=1
            AND post_type = 'post'
            AND post_status IN ( 'publish', 'private', 'draft' )
            AND post_date < '${OLD_STORY_END_DATE}'
            AND ID >= ${OLD_STORY_START_ID}
    )"

# Add other post types
for POST_TYPE in $POST_TYPES; do
    announce "Preparing ${POST_TYPE}s"
    mysql_execute "$(branch_credentials)" \
        "INSERT INTO ${IMPORT_POSTS} (
            SELECT
                ${POST_FIELDS}
            FROM
                ${SOURCE_POSTS}
            WHERE 1=1
                AND post_status = 'publish'
                AND post_type = '${POST_TYPE}'
        )"
done

# Prepare all necessary attachments for our posts that will be  imported
announce "Preparing attachments"
mysql_execute "$(branch_credentials)" \
    "INSERT INTO ${IMPORT_POSTS} (
        SELECT
            ${POST_FIELDS}
        FROM
            ${SOURCE_POSTS}
        WHERE 1=1
            AND post_type = 'attachment'
            AND post_parent IN ( SELECT ID FROM ${IMPORT_POSTS} )
    )"


announce "Dropping existing import meta table"
mysql_execute "$(branch_credentials)" \
    "DROP TABLE IF EXISTS ${IMPORT_META};"

announce "Creating import meta table"
mysql_execute "$(branch_credentials)" \
    "CREATE TABLE ${IMPORT_META} LIKE ${SOURCE_META};"

announce "Preparing post meta"
mysql_execute "$(branch_credentials)" \
    "INSERT INTO ${IMPORT_META} (
        SELECT
            *
        FROM
            ${SOURCE_META}
        WHERE
            post_id IN ( SELECT ID FROM ${IMPORT_POSTS} )
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

announce "Drop existing import terms table"
mysql_execute "$(branch_credentials)" \
    "DROP TABLE IF EXISTS ${IMPORT_TERMS};"

announce "Preparing terms"
mysql_execute "$(branch_credentials)" \
    "CREATE TABLE ${IMPORT_TERMS} LIKE ${SOURCE_TERMS};
        INSERT INTO ${IMPORT_TERMS} (
            SELECT * FROM ${SOURCE_TERMS} WHERE term_id >= ${TERM_ID_START}
        )"

announce "Drop existing import term taxonomy table"
mysql_execute "$(branch_credentials)" \
    "DROP TABLE IF EXISTS ${IMPORT_TT};"

announce "Create import term taxonomies table"
mysql_execute "$(branch_credentials)" \
    "CREATE TABLE ${IMPORT_TT} LIKE ${SOURCE_TT};"

announce "Preparing term taxonomies"
mysql_execute "$(branch_credentials)" \
    "INSERT INTO ${IMPORT_TT} (
        SELECT * FROM ${SOURCE_TT} WHERE term_taxonomy_id >= ${TERM_ID_START}
    )"

announce "Drop existing import term relationships table"
mysql_execute "$(branch_credentials)" \
    "DROP TABLE IF EXISTS ${IMPORT_TR};"

announce "Preparing term relationships"
mysql_execute "$(branch_credentials)" \
    "CREATE TABLE ${IMPORT_TR} AS
        SELECT
            *
        FROM
            ${SOURCE_TR}
        WHERE
            term_taxonomy_id >= ${TERM_ID_START}
        OR
            object_id IN ( SELECT ID FROM ${IMPORT_POSTS} )"

# Add Home page configs? OR is this referring to setting the WP "Reading Settings First Page Displays" option?

# Export the package
announce "Downloading import data package"
mysql_dump \
    "$(branch_credentials)" \
    "${IMPORT_POSTS}" \
    "${IMPORT_META}" \
    "${IMPORT_TERMS}" \
    "${IMPORT_TT}" \
    "${IMPORT_TR}" \
    > import_package.sql
