#!/bin/bash

<<README
This script initiates the installation of the fsdb.
More information on the fsdb at https://gitlab.com/tefor.

PARAMETERS
This script (optionlally) accepts the installation directory as first and only parameter ($1). 

README

#TODO: fix README.md
#TODO: nice-to-have: step counting and cyan messages

# define final installation directory
setpath=0
if [[ -d $1 ]]; then
	defaultInstDir=$(realpath $1)
	setpath=1
fi

# create temporary location for the installation.
# The fsdb will be 'build' within this location and lateron copied/moved into 
# its final location
TMP=$(mktemp -d)
cd $TMP

repo=https://gitlab.com/tefor/fsdb-core.git
printf "\nWelcome to the installer of the file system based database (fsdb).
\t- Step 1: Cloning the latest version of the fsdb from $repo to temporary directory $INITDIR/ \n" 
#git clone --depth 1 -b stable $repo
git clone --depth 1 -b main $repo


#get fsdb-version-number
FSDBVERSION=$(grep FSDBVERSION $(find $TMP -name "fsdb.config") |cut -d " " -f 2)
mkdir $TMP/$FSDBVERSION
mv $(ls  |grep -v $FSDBVERSION) $FSDBVERSION

if [[ $? -gt 0 ]]; then 
	fail "Can't clone fsdb from $repo."
else
	repoName=$(ls -ltr |tail -1 |awk '{print $NF}')
fi
INIT=$(find $(realpath ./$repoName) -name "initializeFsdb.sh")

printf "\nThe following steps need to be executed as super-user (sudo). Please type the corresponding password below.\n"
if [[ $setpath -eq 0 ]]; then
	sudo bash $INIT
else
	sudo bash $INIT $defaultInstDir
fi

rm -rf $TMP
