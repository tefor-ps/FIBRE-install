# fsdb-install

This project conains a single bash script: install-fsdb.sh , which does nothing else but 
- change into a temporary directory - into which the download of the fsdb will happen;
- download the initialization script for the fsdb, and
- run it (as super-user)

```
#!/bin/bash

cd /tmp/ 
wget https://gitlab.com/arnimjenett/fsdb23/-/raw/main/install/initializeFsdb.sh
sudo bash initializeFsdb.sh
```

The easiest way to install the fsdb therefore is to clone this repo and run the contained script.
