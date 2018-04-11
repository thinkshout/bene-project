#! /bin/bash
# Install script for ThinkShout's Bene project

set -e

# Utility functions

function print_help () {
  printf 'Usage:\t%s -d <directory>\n' "$0"
  echo ""
  echo "options:"
  echo "-h, --help            show this text"
  echo "-d, --directory       specify install directory"
}

function check_dir () {
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
  # @TODO 04.11.2018 create-project pulls the WRONG VERSION of this project for some reason
  # @TODO 04.11.2018 copying over pertinent files instead
  # composer create-project thinkshout/bene-project:dev-4-fix-install $ROOT --stability dev --no-interaction
  cp -R ./* $ROOT
  cp ./.env.dist $ROOT
}

function project_setup () {
  echo "...Configuring project"
  composer install
  composer drupal-scaffold
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

  ./vendor/bin/robo configure --db-user=$DB_USER --db-pass=$DB_PASS --db-name=$db_name --profile=bene
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

  mkdir $DEST
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



