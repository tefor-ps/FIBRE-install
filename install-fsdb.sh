#!/bin/bash

<<README
This script initiates the installation of the fsdb.
More information on the fsdb at https://gitlab.com/tefor.

PARAMETERS
This script (optionlally) accepts the installation directory as first and only parameter ($1). 

README

#TODO: fix README.md
#TODO: nice-to-have: step counting and cyan messages

# cyan text on black background to introduce the current script or say something important
intro() { if [[ -t 2 ]] ; then printf $'\r\e[2K\t\e[36;1m'"$@"$'\e[0m\n'; else echo "$@"; fi >&2 ;}

# define final installation directory
setpath=0
if [[ -d $1 ]]; then
	defaultInstDir=$(realpath $1)
	setpath=1
else
	defaultInstDir=$HOME
	setpath=1
fi

# create temporary location for the installation.
# The fsdb will be 'build' within this location and lateron copied/moved into 
# its final location
TMP=$(mktemp -d)
cd $TMP

repo=https://gitlab.com/tefor/fsdb-core.git
intro "\nWelcome to the installer of the file system based database (fsdb).
\t- Step 1: Cloning the latest version of the fsdb 
\t  from $repo 
\t  to the temporary directory $TMP/ \n" 
#git clone --depth 1 -b stable $repo
git clone --depth 1 -b main $repo

#get fsdb-version-number
FSDBVERSION=$(grep FSDBVERSION $(find . -name "fsdb.config*" |tail -1) |cut -d " " -f 2 |awk '{print $1}')
intro "Detected ${FSDBVERSION}."

mkdir -p $TMP/$FSDBVERSION
mv $(ls  |grep -v $FSDBVERSION) $FSDBVERSION

if [[ $? -gt 0 ]]; then 
	fail "Can't clone fsdb from $repo."
else
	repoName=$(ls -ltr |tail -1 |awk '{print $NF}')
fi
INIT=$(find $(realpath ./$repoName) -name "initializeFsdb.sh")

intro "\n\tThe following steps need to be executed as super-user (sudo). 
\tPlease type the corresponding password below.\n"
if [[ $setpath -eq 0 ]]; then
	sudo bash $INIT
else
	sudo bash $INIT $defaultInstDir
fi

sudo rm -rf $TMP
