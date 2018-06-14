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

function setup_child_theme () {
  echo "...Setting up new theme."
  THEME_NAME=`echo $1 | sed 's/.*\///' | sed 's/-/_/g'`
  echo Theme name is $THEME_NAME
  THEME_DEST=$1/web/themes/$THEME_NAME
  echo "Theme will be placed in $THEME_DEST"

  # Make sure it's ok if we remove an existing theme directory. This should never happen for a new bene project.
  EXISTING_DIR=$(check_dir $THEME_DEST)
  if [ "$EXISTING_DIR" == "true" ]; then
    echo -e "${INPUT_COLOR}$THEME_DEST not empty.${NO_COLOR}"
    EXE=$(confirm 'Overwrite? [Y/n]')
    if [ "$EXE" != "true" ]; then
      echo -e "${MSG_COLOR}Aborting.${NO_COLOR}"
      exit 1
    fi
    echo "Removing dir $THEME_DEST"
    rm -rf $THEME_DEST
  fi

  # move bene_child theme into its destination, this also renames from bene_child directory to the new theme name
  mv $1/web/profiles/contrib/bene/themes/bene_child $THEME_DEST

  # go through files and edit them replacing bene_child with the new theme name
  sed "s/bene_child_/${THEME_NAME}_/g" $THEME_DEST/bene_child.theme >$THEME_DEST/$THEME_NAME.theme
  rm $THEME_DEST/bene_child.theme

  sed "s/name: Bene Child/name: ${THEME_NAME}/g" $THEME_DEST/bene_child.info.yml | sed "s/bene_child/${THEME_NAME}/g" >$THEME_DEST/$THEME_NAME.info.yml
  rm $THEME_DEST/bene_child.info.yml

  sed "s/bene_child/${THEME_NAME}/g" $THEME_DEST/bene_child.libraries.yml >$THEME_DEST/$THEME_NAME.libraries.yml
  rm $THEME_DEST/bene_child.libraries.yml

  mv $THEME_DEST/composer.json $THEME_DEST/composer.child
  sed "s/bene_child/${THEME_NAME}/g" $THEME_DEST/composer.child >$THEME_DEST/composer.json
  rm $THEME_DEST/composer.child

  mv $THEME_DEST/package.json $THEME_DEST/package.child
  sed "s/bene_child/${THEME_NAME}/g" $THEME_DEST/package.child >$THEME_DEST/package.json
  rm $THEME_DEST/package.child

  mv $THEME_DEST/package.json $THEME_DEST/package.child
  sed "s/bene_child/${THEME_NAME}/g" $THEME_DEST/package.child >$THEME_DEST/package.json
  rm $THEME_DEST/package.child

  mv $THEME_DEST/README.md $THEME_DEST/README.md.child
  sed "s/Bene Child/${THEME_NAME}/g" $THEME_DEST/README.md.child | sed "s/Bene_child/${THEME_NAME}/g" | sed "s:/new-project-name/web/profiles/contrib/bene/themes/bene_child where new-project-name is your project.:${THEME_DEST}:g" >$THEME_DEST/README.md
  rm $THEME_DEST/README.md.child
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

  echo -e "${INPUT_COLOR}Setup Child Theme?${NO_COLOR}"
  THEME_SETUP=$(confirm '[Y/n]')
  if [ "$THEME_SETUP" == "true" ]; then
    setup_child_theme $DEST
  fi

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



