#! /bin/bash
# Install script for ThinkShout's Bene project

set -e

# Utility functions

function print_help () {
  printf 'Usage:\t%s -d <directory>\n' "$0"
  echo ""
  echo "options:"
  echo "-h, --help            show this text"
  echo "-d, --directory.      specify install directory"
}

function check_dir () {
  # echo "checking $1"
  if [ -d "$1" ]; then
    echo "true"
  else 
    echo "false"
  fi
}

function confirm () {
  read -r -p "${1:-Are you sure? [Y/n]} " response
  case $response in
    [yY][eE][sS]|[yY])
      echo "true"
      ;;
    *)
      echo "false"
      ;;
  esac
}

function composer_setup () {
  echo "...Setting up Bene distro in $1"
  ROOT=$1
  composer create-project thinkshout/bene-project:master $ROOT --stability dev --no-interaction
}

function project_setup () {
  echo "...Configuring project"
  composer install
  ./vendor/bin/robo init
}

function build_project () {
  echo "...Building project"

  echo "Database name: "
  read db_name

  DB_USER='root'
  DB_PASS='root'
  DEFAULT_DB_SETTINGS=$(confirm 'Use root:root for db? [Y/n]')
  if [ "$DEFAULT_DB_SETTINGS" != "true" ]; then
    echo "Database user:"
    read db_user
    DB_USER=$db_user

    echo "Database pass:"
    read db_pass
    beneDB_PASS=$db_pass
  fi

  # @TODO remove
  echo "DB SETTINGS:"
  echo "  name: $db_name"
  echo "  user: $DB_USER"
  echo "  pass: $DB_PASS"

  # @TODO pressflow
  # DEFAULT_PRESSFLOW_SETTINGS_={"databases":{"default":{"default":{"driver":"mysql","prefix":"","database":"","username":"root","password":"root","host":"localhost","port":3306}}},"conf":{"pressflow_smart_start":true,"pantheon_binding":null,"pantheon_site_uuid":null,"pantheon_environment":"local","pantheon_tier":"local","pantheon_index_host":"localhost","pantheon_index_port":8983,"redis_client_host":"localhost","redis_client_port":6379,"redis_client_password":"","file_public_path":"sites\/default\/files","file_private_path":"sites\/default\/files\/private","file_directory_path":"site\/default\/files","file_temporary_path":"\/tmp","file_directory_temp":"\/tmp","css_gzip_compression":false,"js_gzip_compression":false,"page_compression":false},"hash_salt":"","config_directory_name":"sites\/default\/config","drupal_hash_salt":""}

  ./vendor/bin/robo configure --profile=bene
  ./vendor/bin/robo configure --db-name=$db_name
  ./vendor/bin/robo configure --db-user=$DB_USER
  ./vendor/bin/robo configure --db-pass=$DB_PASS
  ./vendor/bin/robo install
}

function git_setup () {
  echo "...Registering git repository"
  git init
  echo "Git repo: "
  read git_repo
  git remote add origin $git_repo
  git add .
  echo "Inital commit message: " 
  read git_msg
  git commit -m "$git_msg"

  git push origin master
}

function perform_install () {
  echo "...Installing Bene";
  DEST=$1
  EXISTING_DIR=$(check_dir $DEST)
  if [ "$EXISTING_DIR" == "true" ]; then
    echo "$DEST not empty."
    EXE=$(confirm 'Overwrite? [Y/n]')
    if [ "$EXE" != "true" ]; then
      echo "Aborting."
      exit 1
    fi
    echo "Removing dir $DEST"
    rm -rf $DEST
  fi

  composer_setup $DEST
  echo "... cd $DEST"
  cd $DEST
  project_setup

  GiT_SETUP=$(confirm 'Setup Git? [Y/n]')
  if [ "$GiT_SETUP" == "true" ]; then
    git_setup
  fi 

  build_project

  echo "...Finshed"
  exit 1
}



# Install script
case "$1" in
  -h|--help)
    print_help
    ;;
  -d|--directory)
    perform_install $2
    ;;
  *)
    print_help
    exit 1
    ;;
esac



