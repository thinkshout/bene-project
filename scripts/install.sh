#! /bin/bash
# Install script for ThinkShout's Bene project

set -e

INPUT_COLOR="\033[1;36m"
MSG_COLOR="\033[0;31m"
NO_COLOR="\033[0m"

# Utility functions

function print_help () {
  printf 'Usage:\t%s -d <directory>\n' "$0"
  echo ""
  echo "options:"
  echo "-h, --help            show this text"
  echo "-d, --directory       *(required) specify install directory"
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

  echo -e "${INPUT_COLOR}Database name:${NO_COLOR}"
  read db_name

  DB_USER='root'
  DB_PASS='root'
  echo -e "${INPUT_COLOR}Use root:root for db?${NO_COLOR}"
  DEFAULT_DB_SETTINGS=$(confirm '[Y/n]')
  if [ "$DEFAULT_DB_SETTINGS" != "true" ]; then
    echo -e "${INPUT_COLOR}Database user:${NO_COLOR}"
    read db_user
    DB_USER=$db_user

    echo -e "${INPUT_COLOR}Database pass:${NO_COLOR}"
    read db_pass
    beneDB_PASS=$db_pass
  fi

  ./vendor/bin/robo configure --db-user=$DB_USER --db-pass=$DB_PASS --db-name=$db_name --profile=bene
  ./vendor/bin/robo install
}

function git_setup () {
  echo "...Registering git repository"
  git init
  echo -e "${INPUT_COLOR}Git repo [ex: git@github.com:thinkshout/bene.git]?${NO_COLOR}"
  read git_repo
  git remote add origin $git_repo
  git add .
  echo -e "${INPUT_COLOR}Initial commit message [ex: 'initial Bene installation']?${NO_COLOR}"
  read git_msg
  git commit -m "$git_msg"

  git push origin master
}

function perform_install () {
  echo "...Installing Bene";
  DEST=$1
  EXISTING_DIR=$(check_dir $DEST)
  if [ "$EXISTING_DIR" == "true" ]; then
    echo -e "${INPUT_COLOR}$DEST not empty.${NO_COLOR}"
    EXE=$(confirm 'Overwrite? [Y/n]')
    if [ "$EXE" != "true" ]; then
      echo -e "${MSG_COLOR}Aborting.${NO_COLOR}"
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

  echo -e "${INPUT_COLOR}Setup Git?${NO_COLOR}"
  GIT_SETUP=$(confirm '[Y/n]')
  if [ "$GIT_SETUP" == "true" ]; then
    git_setup
  fi 

  build_project

  echo -e "${MSG_COLOR}Finshed. Bene installed at $DEST${NO_COLOR}"
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



