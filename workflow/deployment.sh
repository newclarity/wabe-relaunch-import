#!/usr/bin/env bash

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${REPO_ROOT:=}
declare=${IMPORT_PACKAGE_FILE:=}
declare=${SNAPSHOT_FILE:=}

source "${SHARED_SCRIPTS}"

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
        announce "...Cloning database from production to ${DEPLOY_BRANCH}."
        execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --db-only --no-interaction --yes

        announce "...Cloning upload files from production to ${DEPLOY_BRANCH}."
        execute_terminus env:clone-content wabe.live "${DEPLOY_BRANCH}" --files-only --no-interaction --yes
    fi

    #
    # Do some cleanup
    #
    announce "...Dropping infernal Smart Slider tables"
    execute_mysql "DROP TABLE wp_nextend2_image_storage"
    execute_mysql "DROP TABLE wp_nextend2_section_storage"
    execute_mysql "DROP TABLE wp_nextend2_smartslider3_generators"
    execute_mysql "DROP TABLE wp_nextend2_smartslider3_sliders"
    execute_mysql "DROP TABLE wp_nextend2_smartslider3_slides"

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

    announce "...Importing new_terms to wp_terms"
    execute_mysql "INSERT INTO wp_terms
        SELECT * FROM new_terms WHERE term_id NOT IN (SELECT term_id FROM wp_terms);"

    announce "...Importing old_terms to wp_terms"
    execute_mysql "INSERT INTO wp_terms
        SELECT * FROM old_terms WHERE term_id NOT IN (SELECT term_id FROM wp_terms);"

    announce "...Importing new_term_taxonomy to wp_term_taxonomy"
    execute_mysql "INSERT INTO wp_term_taxonomy
        SELECT * FROM new_term_taxonomy WHERE term_taxonomy_id NOT IN (SELECT term_taxonomy_id FROM wp_term_taxonomy);"

    announce "...Importing old_term_taxonomy to wp_term_taxonomy"
    execute_mysql "INSERT INTO wp_term_taxonomy
        SELECT * FROM old_term_taxonomy WHERE term_taxonomy_id NOT IN (SELECT term_taxonomy_id FROM wp_term_taxonomy);"

    announce "...Importing new_term_relationships to wp_term_relationships"
    execute_mysql "INSERT INTO wp_term_relationships
        SELECT * FROM new_term_relationships
            WHERE CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) NOT IN (
                SELECT CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) FROM wp_term_relationships
            )"

    announce "...Importing old_term_relationships to wp_term_relationships"
    execute_mysql "INSERT INTO wp_term_relationships
        SELECT * FROM old_term_relationships
            WHERE CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) NOT IN (
                SELECT CONCAT( CAST(object_id AS char),'-', CAST(term_taxonomy_id AS char) ) FROM wp_term_relationships
            )"

    announce "...Creating a Snapshot of database just assembled"
    dump_mysql "${DEPLOY_BRANCH}" > ${SNAPSHOT_FILE}

    announce "...Importing posts into live tables..."
    execute_terminus wp "wabe.${DEPLOY_BRANCH}" wabe-import

fi

announce "Data conversion scripts complete."

# Set the home page setting

# Set the theme settings

# Set the active theme

