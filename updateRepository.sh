#!/bin/bash

# Name: updateRepository.sh
# Description: Update the packages repository
# Author: Tuxi Metal <tuximetal[at]lgdweb[dot]fr>
# Url: https://github.com/custom-archlinux/iso-sources
# Version: 1.0
# Revision: 2021.06.28
# License: MIT License

workspace="$HOME/ALICE-workspace"
localRepositoryDir="$(pwd)/x86_64/"
systemRepositoryDir="/opt/alice/x86_64/"
databaseName="alice-repo"
commandOptions="--sign --new --remove --verify"
logFile="$(pwd)/$(date +%T).log"

# Helper function for printing messages $1 The message to print
printMessage() {
  message=$1
  tput setaf 2
  echo "-------------------------------------------"
  echo "$message"
  echo "-------------------------------------------"
  tput sgr0
}

isRootUser() {
  if [[ ! "$EUID" = 0 ]]; then 
    printMessage "Please Run As Root"
    exit 0
  fi
  printMessage "Ok to continue running the script"
  sleep .5
}

# Helper function to handle errors
handleError() {
  clear
  set -uo pipefail
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

cleanup() {
  printMessage "Cleanup database and signatures in ${localRepositoryDir}"
  rm -rfv ${systemRepositoryDir}${databaseName}.*
  sleep .5
}

updateRepository() {
  cleanup
  printMessage "Update repository in ${systemRepositoryDir}"
  repo-add ${commandOptions} ${systemRepositoryDir}${databaseName}.db.tar.gz ${systemRepositoryDir}*.pkg.tar.zst
  sleep .5
}

synchronizeRepository() {
  local=$1
  target=$2
  printMessage "Synchronize ${local} repository with ${target} repository"
  rsync -rltv --stats --progress "${local}" "${target}"
  sleep .5
}

changeOwner() {
  newOwner=$1
  directoryName=$2
  printMessage "Change owner of ${directoryName} to ${newOwner}"
  chown -R ${newOwner} ${directoryName}
  sleep .5
}

chooseAction() {
  printMessage "Make a choice: 1 or 2
    1. update db in system repository
    2. sync local repo in system repo"
  read choice
  case $choice in
    1 )
      printMessage "1 update system package repository"
      cleanup
      updateRepository
      synchronizeRepository "${systemRepositoryDir}" "${localRepositoryDir}"
      changeOwner "1000:1000" "${localRepositoryDir}"
    ;;

    2 )
      printMessage "2 sync local repo with system repo"
      rm -rf ${systemRepositoryDir}*
      synchronizeRepository "${localRepositoryDir}" "${systemRepositoryDir}"
    ;;
  esac
}

main() {
  handleError
  chooseAction

  printMessage "All is done!"

  exit 0
}

time main