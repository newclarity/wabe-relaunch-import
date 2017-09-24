#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${REPO_ROOT:=}
declare=${IMPORT_PACKAGE_FILE:=}
declare=${SNAPSHOT_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${GENERATE_SNAPSHOT:=}
declare=${GENERATE_SNAPSHOT_GZIP:=}
declare=${CLONE_LIVE_DATABASE:=}
declare=${CLONE_LIVE_FILES:=}

source "${SHARED_SCRIPTS}"

ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/deployments.log"

DEPLOY_BRANCH="${CIRCLE_BRANCH}"

announce "Set default MySQL environment to ${DEPLOY_BRANCH}"
set_mysql_env "${DEPLOY_BRANCH}"

announce "Running data conversion scripts"

if [ -f "${SNAPSHOT_FILE}" ]; then

    announce "...Importing snapshotted tables and records into working database..."
    import_mysql "${DEPLOY_BRANCH}" < ${IMPORT_PACKAGE_FILE}

    announce "...Show the tables we have now"
    execute_mysql "SHOW TABLES;"

else

    if [ "master" != "${DEPLOY_BRANCH}" ]; then
        if [ "yes" == "${CLONE_LIVE_DATABASE}" ]; then
            announce "...Cloning database from production to ${DEPLOY_BRANCH}."
            execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --db-only --no-interaction --yes
        fi

        if [ "yes" == "${CLONE_LIVE_FILES}" ]; then
            announce "...Cloning upload files from production to ${DEPLOY_BRANCH}."
            execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --files-only --no-interaction --yes
        fi
    fi

    #
    # Do some cleanup
    #
    announce "...Dropping infernal Smart Slider tables"
    execute_mysql "DROP TABLE wp_nextend2_image_storage;
        DROP TABLE wp_nextend2_section_storage;
        DROP TABLE wp_nextend2_smartslider3_generators;
        DROP TABLE wp_nextend2_smartslider3_sliders;
        DROP TABLE wp_nextend2_smartslider3_slides"

    announce "...Importing new tables and records into working database..."
    import_mysql "${DEPLOY_BRANCH}" < ${IMPORT_PACKAGE_FILE}

    announce "...Show the tables we have now"
    execute_mysql "SHOW TABLES;"

    #
    # Add some sanity checks here
    #
    #announce "...Preparing import data to assure no conflicting IDs...";
    #execute_terminus wp "wabe.${DEPLOY_BRANCH}" -- wabe-prepare-import

    announce "...Importing new_posts to wp_posts"
    execute_mysql "INSERT INTO wp_posts
        SELECT * FROM new_posts WHERE ID NOT IN (SELECT ID FROM wp_posts);"

    announce "...Importing old_posts to wp_posts"
    execute_mysql "INSERT INTO wp_posts
        SELECT * FROM old_posts WHERE ID NOT IN (SELECT ID FROM wp_posts);"

    announce "...Importing new_postmeta to wp_postmeta"
    execute_mysql "INSERT INTO wp_postmeta
        SELECT * FROM new_postmeta WHERE meta_id NOT IN (SELECT meta_id FROM wp_postmeta);"

    announce "...Importing old_postmeta to wp_postmeta"
    execute_mysql "INSERT INTO wp_postmeta
        SELECT * FROM old_postmeta WHERE meta_id NOT IN (SELECT meta_id FROM wp_postmeta);"

    #
    # Reduce the size of the postmeta tables a bit
    #
    announce "...Removing _edit_lock and _edit_last from post meta"
    execute_mysql "DELETE FROM wp_postmeta WHERE meta_key='_edit_lock' OR meta_key='_edit_last'"

    announce "...Delete no longer used post meta fields"
    execute_mysql "DELETE FROM wp_postmeta WHERE 1=0
        OR meta_key LIKE 'gaussholder%'
        OR meta_key LIKE '_tailor_%'
        OR meta_key LIKE '_wabe_author[%][person_id]'
        OR meta_key = '_npr_audio'
        OR meta_key = '_wabe_audio_refs'
        OR meta_key = '_wabe_mosaic[after_election_mosaic]'
        OR meta_key = '_wabe_mosaic[election_mosaic]'"

    announce "...Importing new_options into wp_options, deleting selected wp_options"
    execute_mysql "DELETE FROM wp_options WHERE 1=0
            OR option_name LIKE '_transient_%'
            OR option_name LIKE '_site_transient_%
            OR option_name IN (SELECT option_name FROM new_options);
        INSERT INTO wp_options (option_name,option_value,autoload)
        SELECT option_name,option_value,autoload FROM new_options;
        UPDATE wp_options SET option_value='' WHERE option_name='rewrite_rules';"

    announce "...Setting menu locations for wabe-theme in wp_options"
    execute_mysql "
        SELECT @primary_nav_id := term_id FROM wp_terms WHERE name='Primary Navigation (Relaunch)';
        SELECT @footer_nav_id := term_id FROM wp_terms WHERE name='Footer Navigation (Relaunch)';
        UPDATE wp_options
        SET option_value = REPLACE( option_value,'primary_navigation";i:2;',
	        CONCAT('primary_navigation";i:',CAST( @primary_nav_id AS CHAR) COLLATE utf8mb4_general_ci,';')
        ) WHERE option_name = 'theme_mods_wabe-theme';
        UPDATE wp_options
        SET option_value = REPLACE( option_value,'footer_navigation";i:3;',
	        CONCAT('footer_navigation";i:',CAST( @primary_nav_id AS CHAR) COLLATE utf8mb4_general_ci,';')
        ) WHERE option_name = 'theme_mods_wabe-theme';"

    announce "...Importing new_terms into wp_terms"
    execute_mysql "INSERT INTO wp_terms
        SELECT * FROM new_terms WHERE term_id NOT IN (SELECT term_id FROM wp_terms);"

    announce "...Importing old_terms into wp_terms"
    execute_mysql "INSERT INTO wp_terms
        SELECT * FROM old_terms WHERE term_id NOT IN (SELECT term_id FROM wp_terms);"

    announce "...Importing new_term_taxonomy into wp_term_taxonomy"
    execute_mysql "INSERT INTO wp_term_taxonomy
        SELECT * FROM new_term_taxonomy WHERE term_taxonomy_id NOT IN (SELECT term_taxonomy_id FROM wp_term_taxonomy);"

    announce "...Importing old_term_taxonomy into wp_term_taxonomy"
    execute_mysql "INSERT INTO wp_term_taxonomy
        SELECT * FROM old_term_taxonomy WHERE term_taxonomy_id NOT IN (SELECT term_taxonomy_id FROM wp_term_taxonomy);"

    announce "...Importing new_term_relationships into wp_term_relationships"
    execute_mysql "INSERT INTO wp_term_relationships
        SELECT * FROM new_term_relationships
            WHERE CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) NOT IN (
                SELECT CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) FROM wp_term_relationships
            )"

    announce "...Importing old_term_relationships into wp_term_relationships"
    execute_mysql "INSERT INTO wp_term_relationships
        SELECT * FROM old_term_relationships
            WHERE CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) NOT IN (
                SELECT CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) FROM wp_term_relationships
            )"

    announce "...Importing posts into live tables..."
    #execute_terminus wp "wabe.${DEPLOY_BRANCH}" wabe-import

    if [ "yes" = "${GENERATE_SNAPSHOT}" ] ; then
        announce "...Creating a Snapshot of database just assembled"
        dump_mysql "${DEPLOY_BRANCH}" > ${SNAPSHOT_FILE}

        if [ "yes" = "${GENERATE_SNAPSHOT_GZIP}" ] ; then
            announce "...Compressing to ${SNAPSHOT_FILE}.tar.gz"
            tar_gzip "${SNAPSHOT_FILE}"
        fi
    fi
fi

announce "Data conversion scripts complete."


