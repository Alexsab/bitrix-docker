#!/bin/bash

function get_dc_env() {
  gsed -n -e "/${1}/ s/.*\= *//p" .env
}

function fill_placeholder() {
  gsed -ri "s~$1~$2~" .env
}

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
ENV_FILE=.env
#Check if env file exists and offer to recreate it
if [ -f "$ENV_FILE" ]; then
  echo "The .env file already exists."
  echo -n "Would you like to remove it? (Y|N): "
  read -r -e REMOVE_ENV_FILE
  if [ "$(echo "$REMOVE_ENV_FILE" | tr '[:lower:]' '[:upper:]')" == 'Y' ]; then
    rm .env
    cp .env.template .env
  fi
else
  cp .env.template .env
fi

#Ask user to type base paths
CURRENT_DIR=$PWD
PARENT_DIR=$(dirname "$PWD")

if grep -q @PATH_TO_PROJECT@ ".env"; then
  echo -n "Type the project path: [$PARENT_DIR] "
  read -r -e PROJECT_PATH
  PROJECT_PATH=${PROJECT_PATH:-$PARENT_DIR}
  fill_placeholder "@PATH_TO_PROJECT@" "$PROJECT_PATH"
else
  PROJECT_PATH=$(get_dc_env PROJECT_PATH)
fi

COMPOSE_PROJECT_NAME=${PROJECT_PATH%*/}

if grep -q @YOUR_PROJECT_NAME@ ".env"; then
  DEFAULT_PROJECT_NAME=$(gsed s~-~_~g <<<${COMPOSE_PROJECT_NAME##*/})
  echo -n "Type the project name: [$DEFAULT_PROJECT_NAME] "
  read -r -e COMPOSE_PROJECT_NAME
  COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-$DEFAULT_PROJECT_NAME}
  fill_placeholder "@YOUR_PROJECT_NAME@" "$COMPOSE_PROJECT_NAME"
else
  COMPOSE_PROJECT_NAME=$(get_dc_env COMPOSE_PROJECT_NAME)
fi

if grep -q @YOUR_PROJECT_DOMAIN@ ".env"; then
  DEFAULT_DOMAIN="${COMPOSE_PROJECT_NAME}.loc"
  echo -n "Type the domain for project: [$DEFAULT_DOMAIN] "
  read -r -e PROJECT_DOMAIN
  PROJECT_DOMAIN=${PROJECT_DOMAIN:-$DEFAULT_DOMAIN}
  fill_placeholder "@YOUR_PROJECT_DOMAIN@" "$PROJECT_DOMAIN"
else
  PROJECT_DOMAIN=$(get_dc_env DOMAIN)
fi

if grep -q @PATH_TO_DOCKER_DATA@ ".env"; then
  DEFAULT_DATA_PATH="$CURRENT_DIR/data"
  echo -n "Type the path to docker data: [$DEFAULT_DATA_PATH] "
  read -r -e DATA_PATH
  DATA_PATH=${DATA_PATH:-$DEFAULT_DATA_PATH}
  fill_placeholder "@PATH_TO_DOCKER_DATA@" "$DATA_PATH"
else
  DATA_PATH=$(get_dc_env DATA_PATH)
fi

if grep -q @PATH_TO_LOGS@ ".env"; then
  DEFAULT_LOGS_PATH="$CURRENT_DIR/logs"
  echo -n "Type the log path: [$DEFAULT_LOGS_PATH] "
  read -r -e LOGS_PATH
  LOGS_PATH=${LOGS_PATH:-$DEFAULT_LOGS_PATH}
  fill_placeholder "@PATH_TO_LOGS@" "$LOGS_PATH"
else
  LOGS_PATH=$(get_dc_env LOGS_PATH)
fi

for TMP in "tmp" "tmp/php_sessions"; do
  mkdir -p "./$TMP"
done

for DIRECTORY in "supervisor" "mysql" "nginx" "php"; do
  mkdir -p "$LOGS_PATH/$DIRECTORY"
done

#Create public directory
if [ ! -d "${PROJECT_PATH}/public" ]; then
  echo -n "Create public folder with index.php? [Y]: "
  read -r -e CREATE_PUBLIC
  CREATE_PUBLIC=${CREATE_PUBLIC:-'Y'}
  if [ "$(echo "$CREATE_PUBLIC" | tr '[:lower:]' '[:upper:]')" == 'Y' ]; then
    mkdir "${PROJECT_PATH}/public" && echo '<?php phpinfo();' >"${PROJECT_PATH}/public/index.php"
  fi
fi

echo -n 'Download bitrix_setup.php? [Y]: '
read -r -e DBS
DBS=${DBS:-'Y'}

if [ "${DBS}" == 'Y' ]; then
  wget "https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php" -O "${PROJECT_PATH}/public/bitrixsetup.php" -nv
  echo "File is downloaded."
fi
