#!/usr/bin/env bash

source ${SHARED_SCRIPTS}

OLD_STORY_START_ID=375000
OLD_STORY_END_ID=407946
OLD_STORY_END_DATE="2015-10-01"

POST_TYPES=("wabe_person" "wabe_show" "wabe_guide" "page" "nav-menu-item")
NEW_META_START_ID=4000000
TERM_ID_START=2000

POSTS_DEST="import_posts"
META_DEST="import_postmeta"
TERMS_DEST="import_terms"
TT_DEST="import_term_taxonomy"
TR_DEST="import_term_relationships"

POSTS_SOURCE="wp_posts"
META_SOURCE="wp_postmeta"
TERMS_SOURCE="wp_terms"
TT_SOURCE="wp_term_taxonomy"
TR_SOURCE="wp_term_relationships"

PREVIEW_HOSTNAME=dbserver.preview.d5981687-a2b6-4a2c-9456-ae933c90b097.drush.in
PREVIEW_USERNAME=pantheon
PREVIEW_PASSWORD=5d2c4707db8b42f6900ad610d74ad362
PREVIEW_PORT=16159
PREVIEW_DBNAME=pantheon

# This is due to a strange behavior where using the '*' in the SQL would expand into a listing of directory contents
POST_FIELDS="ID, post_author, post_date, post_date_gmt, post_content, post_title, post_excerpt, post_status, comment_status, ping_status,
post_password, post_name, to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent, guid,
menu_order, post_type, post_mime_type, comment_count"


function mysql_preview() {

    mysql -h "${PREVIEW_HOSTNAME}" -u "${PREVIEW_USERNAME}" -p"${PREVIEW_PASSWORD}" -P "${PREVIEW_PORT}" "${PREVIEW_DBNAME}" -e "$1"

}

# Add old stories
announce "Drop existing import posts table"
mysql_preview "
DROP TABLE IF EXISTS ${POSTS_DEST};"

announce "Create import posts table"
mysql_preview "
CREATE TABLE ${POSTS_DEST} LIKE ${POSTS_SOURCE};"

announce "Preparing old stories"
mysql_preview "
INSERT INTO
    ${POSTS_DEST} (
        SELECT
            ${POST_FIELDS}
        FROM
            ${POSTS_SOURCE}
        WHERE 1=1
        AND
            post_type = 'post'
        AND
            post_status = 'publish'
        AND
            post_date < '${OLD_STORY_END_DATE}'
        AND
            ID >= 375000
    )"

# Add other post types
for POST_TYPE in "${POST_TYPES[@]}"
do
    :
    announce "Preparing ${POST_TYPE}s"
    mysql_preview "
    INSERT INTO
        ${POSTS_DEST} (
            SELECT
                ${POST_FIELDS}
            FROM
                ${POSTS_SOURCE}
            WHERE 1=1
            AND
                post_type = '${POST_TYPE}'
            AND
                post_status = 'publish'
        )"
done

# Prepare all necessary attachments for our posts that will be  imported
announce "Preparing attachments"
mysql_preview "
INSERT INTO
    ${POSTS_DEST} (
    SELECT
        ${POST_FIELDS}
    FROM
        ${POSTS_SOURCE}
    WHERE 1=1
    AND
        post_type = 'attachment'
    AND
        post_parent IN (
            SELECT
                ID
            FROM
                ${POSTS_DEST}
        )
    )"


announce "Dropping existing import meta table"
mysql_preview "
DROP TABLE IF EXISTS ${META_DEST};"

announce "Creating import meta table"
mysql_preview "
CREATE TABLE ${META_DEST} LIKE ${META_SOURCE};"

announce "Preparing post meta"
mysql_preview "
INSERT INTO
    ${META_DEST} (
        SELECT
            *
        FROM
            ${META_SOURCE}
        WHERE 1=1
        AND
            meta_key  IN ( 'npr_author_xml', 'npr_story_xml', '_wabe_story_authors', '_wabe_attribution_processed', '_wabe_authors_imported_from_xml', '_wabe_photo_agency', '_wabe_photo_agency_url', '_wabe_photo_credit', '_wabe_photo_npr_image_id' )
        OR
            post_id IN (
                SELECT
                    ID
                FROM
                    ${POSTS_DEST}
            )
    )"

announce "Drop existing import terms table"
mysql_preview "
DROP TABLE IF EXISTS ${TERMS_DEST};"

announce "Preparing terms"
mysql_preview "
CREATE TABLE ${TERMS_DEST} LIKE ${TERMS_SOURCE};
INSERT INTO
    ${TERMS_DEST} (
        SELECT
            *
        FROM
            ${TERMS_SOURCE}
        WHERE 1=1
        AND
            term_id >= ${TERM_ID_START}
    )"

announce "Drop existing import term taxonomy table"
mysql_preview "
DROP TABLE IF EXISTS ${TT_DEST};"

announce "Create import term taxonomies table"
mysql_preview "
CREATE TABLE ${TT_DEST} LIKE ${TT_SOURCE};"

announce "Preparing term taxonomies"
mysql_preview "
INSERT INTO
    ${TT_DEST} (
        SELECT
            *
        FROM
            ${TT_SOURCE}
        WHERE 1=1
        AND
            term_taxonomy_id >= ${TERM_ID_START}
    )"

announce "Drop existing import term relationships table"
mysql_preview "
DROP TABLE IF EXISTS ${TR_DEST};"

announce "Preparing term relationships"
mysql_preview "
CREATE TABLE
    ${TR_DEST}
SELECT
    *
FROM
    ${TR_SOURCE}
WHERE 1=1
AND
    object_id IN (
        SELECT
            ID
        FROM
            import_posts
    )
OR
    term_taxonomy_id >= ${TERM_ID_START}"

# Add Home page configs? OR is this referring to setting the WP "Reading Settings First Page Displays" option?

# Export the package
announce "Downloading import data package"
mysqldump --host "${PREVIEW_HOSTNAME}" --user "${PREVIEW_USERNAME}" -p"${PREVIEW_PASSWORD}" --port "${PREVIEW_PORT}" "${PREVIEW_DBNAME}" "${POSTS_DEST}" "${META_DEST}" "${TERMS_DEST}" "${TT_DEST}" "${TR_DEST}" > import_package.sql
