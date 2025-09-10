# fsdb-install

This project conains a single bash script: install-fsdb.sh , which does nothing else but 
- change into a temporary directory - into which the download of the fsdb will happen;
- download the initialization script for the fsdb, and
- run it (as super-user)

```
#!/bin/bash

TMP=$(mktemp -d)
cd $TMP
wget https://gitlab.com/tefor/fsdb-core/-/raw/stable/install/initializeFsdb.sh

sudo bash initializeFsdb.sh

rm -rf $TMP
```

The easiest way to install the fsdb therefore is to clone this repo and run the contained script.
