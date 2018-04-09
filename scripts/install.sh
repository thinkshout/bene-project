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
  ROOT=$1
  echo "...Setting up Bene distro in $ROOT"
  composer create-project thinkshout/bene-project:master $ROOT --stability dev --no-interaction
}

function git_setup () {
  echo "Registering git repository"
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
    
    # composer create-project thinkshout/bene-project:master $DEST --stability dev --no-interaction

    # echo "Setting up project"
    # cd $DEST

    # echo "Setup .git repository?"
    # confirm && git_setup
  fi

  # composer_setup $DEST

  GiT_SETUP=$(confirm 'Setup Git? [Y/n]')
  if [ "$GiT_SETUP" == "true" ]; then
    git_setup
  fi 

  echo "...Finshed"
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



