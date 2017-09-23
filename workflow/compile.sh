#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}

declare=${STARTING_POST_ID:=}
declare=${ENDING_POST_DATE:=}

declare=${POST_TYPES:=}
declare=${STARTING_TERM_ID:=}
declare=${MYSQL_ROOT:=}
declare=${META_KEYS:=}
declare=${TAXONOMIES:=}
declare=${IMPORT_PACKAGE_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}

source ${SHARED_SCRIPTS}

ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/compile.log"

if [ -f "${IMPORT_PACKAGE_FILE}" ] ; then
    announce "Using cached ${IMPORT_PACKAGE_FILE}"
    return
else
    announce "Creating and then caching ${IMPORT_PACKAGE_FILE}"
fi

#
# This is due to a strange behavior where using the '*' in
# the SQL would expand into a listing of directory contents
#
POST_FIELDS="ID, post_author, post_date, post_date_gmt, post_content, post_title,
    post_excerpt, post_status, comment_status, ping_status, post_password, post_name,
    to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent,
    guid, menu_order, post_type, post_mime_type, comment_count"

set_mysql_env "preview"

# Add old stories
announce "...Drop existing import posts table on 'preview'"
execute_mysql "DROP TABLE IF EXISTS new_posts"

announce "...Create import posts table on 'preview'"
execute_mysql "CREATE TABLE new_posts LIKE wp_posts"

#announce "...Preparing old stories on 'preview'"
#execute_mysql "INSERT INTO new_posts (
#        SELECT
#            ${POST_FIELDS}
#        FROM
#            wp_posts
#        WHERE 1=1
#            AND post_type = 'post'
#            AND post_status IN ( 'publish', 'private', 'draft' )
#            AND post_date < '${ENDING_POST_DATE}'
#            AND ID >= ${STARTING_POST_ID}
#    )"


#
# Add post types that are primarily sourced on `preview`
#

post_types="$(quote_mysql_set "${POST_TYPES}")"
announce "...Exporting post types source on 'preview' to new_posts"
execute_mysql "INSERT INTO new_posts (
    SELECT
        ${POST_FIELDS}
    FROM
        wp_posts
    WHERE 1=1
        AND post_status IN ('publish','private','draft','revision','inherit')
        AND post_type IN (${post_types})
    )"


# Prepare all necessary attachments for our posts that will be  imported
announce "...Preparing attachments on 'preview'"
execute_mysql "INSERT INTO new_posts (
    SELECT
        ${POST_FIELDS}
    FROM
        wp_posts
    WHERE 1=1
        AND post_type = 'attachment'
        AND post_parent IN ( SELECT ID FROM new_posts )
    )"


announce "...Dropping existing import meta table on 'preview'"
execute_mysql "DROP TABLE IF EXISTS new_postmeta;"

announce "...Creating import meta table on 'preview'"
execute_mysql "CREATE TABLE new_postmeta LIKE wp_postmeta;"

meta_keys="$(quote_mysql_set "${META_KEYS}")"
announce "...Preparing post meta on 'preview'"
execute_mysql "INSERT INTO new_postmeta
    SELECT * FROM wp_postmeta WHERE post_id IN (SELECT ID FROM new_posts) OR meta_key IN ( ${meta_keys} );"

announce "...Drop existing import terms table on 'preview'"
execute_mysql "DROP TABLE IF EXISTS new_terms;"

taxonomies="$(quote_mysql_set "${TAXONOMIES}")"
announce "...Preparing terms on 'preview'"
execute_mysql "CREATE TABLE new_terms LIKE wp_terms;
    INSERT INTO new_terms
    SELECT * FROM wp_terms WHERE term_id >= ${STARTING_TERM_ID} OR term_id IN (
        SELECT term_id FROM wp_term_taxonomy WHERE taxonomy IN (${taxonomies})
    );"

announce "...Drop existing import term taxonomy table on 'preview'"
execute_mysql "DROP TABLE IF EXISTS new_term_taxonomy;"

announce "...Create import term taxonomies table on 'preview'"
execute_mysql "CREATE TABLE new_term_taxonomy LIKE wp_term_taxonomy;"

announce "...Preparing term taxonomies on 'preview'"
execute_mysql "INSERT INTO new_term_taxonomy
    SELECT * FROM wp_term_taxonomy WHERE term_taxonomy_id>=${STARTING_TERM_ID} OR term_id IN (SELECT term_id FROM new_terms)"

announce "...Drop existing import term relationships table on 'preview'"
execute_mysql "DROP TABLE IF EXISTS new_term_relationships;"

announce "...Create import term relationships table on 'preview'"
execute_mysql "CREATE TABLE new_term_relationships LIKE wp_term_relationships;"

announce "...Preparing term relationships on 'preview'"
execute_mysql "INSERT INTO new_term_relationships
    SELECT * FROM wp_term_relationships WHERE term_taxonomy_id>=${STARTING_TERM_ID}
        OR object_id IN (SELECT ID FROM new_posts)
        OR term_taxonomy_id IN (SELECT term_taxonomy_id FROM new_term_taxonomy) "

# Add Home page configs? OR is this referring to setting the WP "Reading Settings First Page Displays" option?

# Export the package
announce "...Creating ${IMPORT_PACKAGE_FILE} from 'preview'"
dump_mysql preview \
    old_api_links \
    old_posts \
    old_postmeta \
    old_show_posts \
    old_story_ids \
    old_story_xml \
    old_terms \
    old_term_taxonomy \
    old_term_relationships \
    new_posts \
    new_postmeta \
    new_terms \
    new_term_taxonomy \
    new_term_relationships \
    > ${IMPORT_PACKAGE_FILE}

#
# Make it smaller
#
announce "...Compressing to ${IMPORT_PACKAGE_FILE}.tar.gz"
tar_gzip "${IMPORT_PACKAGE_FILE}"

announce "Import package ${IMPORT_PACKAGE_FILE} created"

