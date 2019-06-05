#! /bin/bash
# Install script for ThinkShout's Bene project

set -e

INPUT_COLOR="\033[1;36m"
MSG_COLOR="\033[0;32m"
ERROR_COLOR="\033[0;31m"
NO_COLOR="\033[0m"

# Ensure the working directory is the project root directory.

cd "${0%/*}/../"

PROJECT_NAME=$(basename "$PWD")

# Utility functions

function print_help () {
  printf 'Usage:\t%s -d <directory>\n' "$0"
  echo ""
  echo "options:"
  echo "-h, --help            show this text"
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

function project_setup () {
  echo "...Configuring project"
  composer install
  composer drupal-scaffold
  ./vendor/bin/robo init
}

function build_project () {
  echo "...Building project"

  while [ -z "$db_name" ]; do
    echo -e "${INPUT_COLOR}Database name:${NO_COLOR}"
    read db_name
  done

  DB_USER='root'
  DB_PASS='root'
  echo -e "${INPUT_COLOR}Use root:root for db?${NO_COLOR}"
  DEFAULT_DB_SETTINGS=$(confirm '[Y/n]')
  if [ "$DEFAULT_DB_SETTINGS" != "true" ]; then
    echo -e "${INPUT_COLOR}Database user:${NO_COLOR}"
    read db_user
    DB_USER="$db_user"

    echo -e "${INPUT_COLOR}Database pass:${NO_COLOR}"
    read db_pass
    DB_PASS="$db_pass"
  fi

  ./vendor/bin/robo configure --db-user="$DB_USER" --db-pass="$DB_PASS" --db-name="$db_name" --profile="bene"
  echo "...Installing the Bene profile"
  if [ ! -f "web/sites/default/settings.local.php" ]; then
    cp scripts/templates/settings.local.php web/sites/default/settings.local.php
    sed -i.bak -e "s/DB_NAME/${db_name}/" -e "s/DB_USER/${DB_USER}/" -e "s/DB_PASS/${DB_PASS}/" web/sites/default/settings.local.php
    rm web/sites/default/*.bak
  fi
  if ! grep -q bene-project web/sites/default/settings.php; then
    cat scripts/templates/settings.partial.php >> web/sites/default/settings.php
  fi
  cd web
  ../vendor/bin/drush site-install bene
  cd ..
}

function git_setup () {
  echo "...Registering git repository"
  git init
  while [ -z "$git_repo_temp" ]; do
    echo -e "${INPUT_COLOR}Git repo [ex: git@github.com:thinkshout/bene.git]?${NO_COLOR}"
    read git_repo_temp
  done

  while [ -z "$git_repo" ]; do
    git ls-remote "$git_repo_temp" -q
    if [ $? == "0" ]; then
      git_repo="$git_repo_temp"
    fi
  done

  git remote add origin $git_repo
  git add .

  while [ -z "$git_msg" ]; do
    echo -e "${INPUT_COLOR}Initial commit message [ex: 'Initial Bene installation']?${NO_COLOR}"
    read git_msg
  done
  git commit -m "$git_msg"

  git push origin master
}

function setup_child_theme () {
  echo "...Setting up new theme."
  DEFAULT_THEME_NAME=`echo $1 | sed 's/.*\///' | sed 's/-/_/g'`
  while [ -z "$THEME_NAME" ]; do
    echo -e "${INPUT_COLOR}Is the default theme name $DEFAULT_THEME_NAME OK?${NO_COLOR}"
    DEFAULT_THEME=$(confirm '[Y/n]')
    if [ "$DEFAULT_THEME" != "true" ]; then
      while [ -z "$custom_theme_name" ]; do
        echo -e "${INPUT_COLOR}Custom theme name:${NO_COLOR}"
        read custom_theme_name
        THEME_NAME="$custom_theme_name"
      done
    else
      THEME_NAME="$DEFAULT_THEME_NAME"
    fi
  done
  THEME_DEST=web/themes/$THEME_NAME
  echo "Theme will be placed in $THEME_DEST"

  # Make sure it's ok if we remove an existing theme directory. This should never happen for a new bene project.
  EXISTING_DIR=$(check_dir $THEME_DEST)
  if [ "$EXISTING_DIR" == "true" ]; then
    echo -e "${INPUT_COLOR}$THEME_DEST not empty.${NO_COLOR}"
    EXE=$(confirm 'Overwrite? [Y/n]')
    if [ "$EXE" != "true" ]; then
      echo -e "${ERROR_COLOR}Aborting.${NO_COLOR}"
      exit 1
    fi
    echo "Removing dir $THEME_DEST"
    rm -rf $THEME_DEST
  fi

  # Copy bene_child theme into its destination, this also renames from bene_child directory to the new theme name.
  cp -r web/profiles/contrib/bene/themes/bene_child $THEME_DEST
  mv "${THEME_DEST}/bene_child.theme" "${THEME_DEST}/${THEME_NAME}.theme"
  mv "${THEME_DEST}/bene_child.libraries.yml" "${THEME_DEST}/${THEME_NAME}.libraries.yml"
  mv "${THEME_DEST}/bene_child.info.yml" "${THEME_DEST}/${THEME_NAME}.info.yml"
  sed -i.bak "s/[bB]ene.[cC]hild/${THEME_NAME}/g" "${THEME_DEST}/${THEME_NAME}.theme" "${THEME_DEST}/${THEME_NAME}.libraries.yml" "${THEME_DEST}/${THEME_NAME}.info.yml" "${THEME_DEST}/README.md" "${THEME_DEST}/composer.json" "${THEME_DEST}/package.json"
  rm $THEME_DEST/*.bak

  cd web
  ../vendor/bin/drush en $THEME_NAME -y
  ../vendor/bin/drush config-set system.theme default $THEME_NAME -y
  ../vendor/bin/drush cr
  cd ..
}

function perform_install () {
  echo "...Installing Bene";

  project_setup

  build_project

  echo -e "${INPUT_COLOR}Setup Child Theme?${NO_COLOR}"
  THEME_SETUP=$(confirm '[Y/n]')
  if [ "$THEME_SETUP" == "true" ]; then
    setup_child_theme $PROJECT_NAME
  fi

  echo -e "${INPUT_COLOR}Setup Git?${NO_COLOR}"
  GIT_SETUP=$(confirm '[Y/n]')
  if [ "$GIT_SETUP" == "true" ]; then
    git_setup
  fi

  echo -e "${MSG_COLOR}Finished installing Bene.${NO_COLOR}"
  exit 1
}

# Install script
case "$1" in
  -h|--help)
    print_help
    ;;
  *)
    perform_install
    ;;
esac
