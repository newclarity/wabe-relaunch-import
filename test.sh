#!/usr/bin/env bash

MYSQL_ENV=""
function set_mysql_env() {
    MYSQL_ENV="$1"
    BRANCH="${2:-${MYSQL_ENV}}"
    echo $BRANCH
}



echo "$(set_mysql_env "foo")"
echo "$(set_mysql_env "foo" "bar")"
