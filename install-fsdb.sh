#!/bin/bash

<<README
This script initiates the installation of the fsdb.
more infos on the fsdb at https://gitlab.com/tefor.

PARAMETERS
This script (optionlally) accepts the installation directory as first and only parameter ($1). 

README

# define final installation directory
setpath=0
if [[ -d $1 ]]; then
	defaultInstDir=$(realpath $1)
	setpath=1
fi

TMP=$(mktemp -d)
cd $TMP
wget https://gitlab.com/tefor/fsdb-core/-/raw/main/install/initializeFsdb.sh

if [[ $setpath -eq 0 ]]; then
	sudo bash initializeFsdb.sh
else
	sudo bash initializeFsdb.sh $defaultInstDir
fi

rm -rf $TMP
