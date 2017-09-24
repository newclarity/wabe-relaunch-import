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
declare=${MENU_ID_OFFSET:=}
declare=${MENU_ITEM_ID_OFFSET:=}
declare=${MENU_ITEM_META_ID_OFFSET:=}
declare=${REGEN_IMPORT_PACKAGE:=}
declare=${REGEN_MENU_IMPORTS:=}
declare=${GENERATE_IMPORT_PACKAGE_GZIP:=}


source ${SHARED_SCRIPTS}

ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/compile.log"

if [ "yes" = "${REGEN_IMPORT_PACKAGE}" ]; then
    rm -f "${IMPORT_PACKAGE_FILE}"
fi

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
#POST_FIELDS="ID, post_author, post_date, post_date_gmt, post_content, post_title,
#    post_excerpt, post_status, comment_status, ping_status, post_password, post_name,
#    to_ping, pinged, post_modified, post_modified_gmt, post_content_filtered, post_parent,
#    guid, menu_order, post_type, post_mime_type, comment_count"

set_mysql_env "preview"

if [ "yes" = "${REGEN_MENU_IMPORTS}" ]; then
    announce "...Generating new menus tables from 'preview'"

    announce "......Generating new_menus from wp_terms on 'preview'"
    execute_mysql "DROP TABLE IF EXISTS new_menus;
        CREATE TABLE new_menus LIKE wp_terms;
        INSERT new_menus
        SELECT * FROM wp_terms WHERE name LIKE '%(Relaunch)';
        ALTER TABLE new_menus MODIFY COLUMN term_id bigint(20) UNSIGNED NOT NULL FIRST;"

    announce "......Generating new_menu_taxonomy from wp_term_taxonomy on 'preview'"
    execute_mysql "DROP TABLE IF EXISTS new_menu_taxonomy;
        CREATE TABLE new_menu_taxonomy LIKE wp_term_taxonomy;
        INSERT new_menu_taxonomy
        SELECT * FROM wp_term_taxonomy WHERE term_id IN (SELECT term_id FROM new_menus);
        ALTER TABLE new_menu_taxonomy MODIFY COLUMN term_taxonomy_id bigint(20) UNSIGNED NOT NULL FIRST;"

    announce "......Generating new_menu_items from wp_posts on 'preview'"
    execute_mysql "DROP TABLE IF EXISTS new_menu_items;
        CREATE TABLE new_menu_items LIKE wp_posts;
        INSERT new_menu_items
        SELECT * FROM wp_posts WHERE ID IN (SELECT object_id FROM new_menu_relationships);
        ALTER TABLE new_menu_items MODIFY COLUMN ID bigint(20) UNSIGNED NOT NULL FIRST;"

    announce "......Generating new_menu_items from wp_posts on 'preview'"
    execute_mysql "DROP TABLE IF EXISTS new_menu_item_meta;
        CREATE TABLE new_menu_item_meta LIKE wp_postmeta;
        INSERT new_menu_item_meta
        SELECT * FROM wp_postmeta WHERE post_id IN (SELECT ID FROM new_menu_items);
        ALTER TABLE new_menu_item_meta MODIFY COLUMN meta_id bigint(20) UNSIGNED NOT NULL FIRST;"

    announce "......Generating new_menu_relationships from wp_term_relationships on 'preview'"
    execute_mysql "DROP TABLE IF EXISTS new_menu_relationships;
        CREATE TABLE new_menu_relationships LIKE wp_term_relationships;
        INSERT new_menu_relationships
        SELECT * FROM wp_term_relationships WHERE term_taxonomy_id
            IN (SELECT term_taxonomy_id FROM new_menu_taxonomy);"

    announce "......Add ID offsets for menu tables"
    execute_mysql "
        UPDATE new_menus SET term_id=term_id+${MENU_ID_OFFSET};
        UPDATE new_menu_taxonomy SET term_id=term_id+${MENU_ID_OFFSET}, term_taxonomy_id=term_taxonomy_id+${MENU_ID_OFFSET};
        UPDATE new_menu_relationships SET object_id=object_id+${MENU_ITEM_ID_OFFSET}, term_taxonomy_id=term_taxonomy_id+${MENU_ID_OFFSET};
        UPDATE new_menu_items SET ID=ID+${MENU_ITEM_ID_OFFSET}, post_parent=post_parent+${MENU_ITEM_ID_OFFSET};
        UPDATE new_menu_item_meta SET meta_id=meta_id+${MENU_ITEM_META_ID_OFFSET}, post_id=post_id+${MENU_ITEM_ID_OFFSET};"

    announce "......Offset menu parent IDs in new_menu_item_meta on 'preview'"
    execute_mysql " CREATE TEMPORARY TABLE menu_item_menu_item_parent AS
        SELECT meta_id, CAST(meta_value AS signed) + ${MENU_ITEM_ID_OFFSET} AS post_id FROM new_menu_item_meta
            WHERE CAST(meta_value AS signed) > 0 AND meta_key='_menu_item_menu_item_parent';
        UPDATE new_menu_item_meta nmim INNER JOIN menu_item_menu_item_parent mimip ON nmim.meta_id=mimip.meta_id
            SET nmim.meta_value = mimip.post_id;"

    announce "......Offset menu item reference post IDs in new_menu_item_meta on 'preview'"
    execute_mysql " CREATE TEMPORARY TABLE menu_item_object_id AS
        SELECT meta_id, CAST(meta_value AS signed) + ${MENU_ITEM_ID_OFFSET} AS post_id FROM new_menu_item_meta
            WHERE CAST(meta_value AS signed) > 0 AND meta_key='_menu_item_object_id';
        UPDATE new_menu_item_meta nmim INNER JOIN menu_item_object_id mioi ON nmim.meta_id=mioi.meta_id
            SET nmim.meta_value = mioi.post_id;"

fi

function regen_menu_sql() {
    if [ "yes" = "${REGEN_MENU_IMPORTS}" ]; then 
        echo "SELECT * FROM $1 UNION"
    fi 
}

#
# Add post types that are primarily sourced on 'preview'
#

announce "...Generating new_posts from wp_posts on 'preview'"
post_types="$(quote_mysql_set "${POST_TYPES}")"
regen_sql="$(regen_menu_sql "new_menu_items")"
execute_mysql "DROP TABLE IF EXISTS new_posts;
    CREATE TABLE new_posts LIKE wp_posts;
    INSERT INTO new_posts ${regen_sql}
    SELECT * FROM wp_posts WHERE 1=1
        AND post_status IN ('publish','private','draft','revision','inherit')
        AND post_type IN (${post_types});"

announce "...Inserting attachments in new_posts from wp_posts on 'preview'"
execute_mysql "INSERT INTO new_posts
    SELECT * FROM wp_posts WHERE 1=1
        AND post_type = 'attachment'
        AND post_parent IN ( SELECT ID FROM new_posts )"

announce "...Generating new_postmeta from wp_postmeta on 'preview'"
meta_keys="$(quote_mysql_set "${META_KEYS}")"
regen_sql="$(regen_menu_sql "new_menu_item_meta")"
execute_mysql "DROP TABLE IF EXISTS new_postmeta;
    CREATE TABLE new_postmeta LIKE wp_postmeta;
    INSERT INTO new_postmeta ${regen_sql}
    SELECT * FROM wp_postmeta WHERE post_id IN (SELECT ID FROM new_posts) OR meta_key IN ( ${meta_keys} );"

announce "...Generating new_terms from wp_terms on 'preview'"
taxonomies="$(quote_mysql_set "${TAXONOMIES}")"
regen_sql="$(regen_menu_sql "new_menus")"
execute_mysql "DROP TABLE IF EXISTS new_terms;
    CREATE TABLE new_terms LIKE wp_terms;
    INSERT INTO new_terms ${regen_sql}
    SELECT * FROM wp_terms WHERE term_id >= ${STARTING_TERM_ID} OR term_id IN (
        SELECT term_id FROM wp_term_taxonomy WHERE taxonomy IN (${taxonomies})
    );"

announce "...Generating new_term_taxonomy from wp_term_taxonomy on 'preview'"
regen_sql="$(regen_menu_sql "new_menu_taxonomy")"
execute_mysql "DROP TABLE IF EXISTS new_term_taxonomy;
    CREATE TABLE new_term_taxonomy LIKE wp_term_taxonomy;
    INSERT INTO new_term_taxonomy ${regen_sql}
    SELECT * FROM wp_term_taxonomy WHERE 1=0
        OR term_taxonomy_id>=${STARTING_TERM_ID}
        OR term_id IN (SELECT term_id FROM new_terms);"

announce "...Generating new_term_relationships table from wp_term_relationships on 'preview'"
regen_sql="$(regen_menu_sql "new_menu_relationships")"
execute_mysql "DROP TABLE IF EXISTS new_term_relationships;
    CREATE TABLE new_term_relationships LIKE wp_term_relationships;
    INSERT INTO new_term_relationships ${regen_sql}
    SELECT * FROM wp_term_relationships WHERE term_taxonomy_id>=${STARTING_TERM_ID}
        OR object_id IN (SELECT ID FROM new_posts)
        OR term_taxonomy_id IN (SELECT term_taxonomy_id FROM new_term_taxonomy);"


# Add Home page configs? OR is this referring to setting the WP "Reading Settings First Page Displays" option?

# Export the package
announce "...Creating ${IMPORT_PACKAGE_FILE} from 'preview'"
dump_mysql preview \
    old_posts \
    old_postmeta \
    old_show_posts \
    old_terms \
    old_term_taxonomy \
    old_term_relationships \
    new_posts \
    new_postmeta \
    new_terms \
    new_term_taxonomy \
    new_term_relationships \
    > ${IMPORT_PACKAGE_FILE}


if [ "yes" = "${GENERATE_IMPORT_PACKAGE_GZIP}" ]; then 
    #
    # Make it smaller
    #
    announce "...Compressing to ${IMPORT_PACKAGE_FILE}.tar.gz"
    tar_gzip "${IMPORT_PACKAGE_FILE}"
fi

announce "Import package ${IMPORT_PACKAGE_FILE} created"
