# fsdb - file system based database

The fsdb organizes the transfer and management of (multidimensional) image data sets from their image acquisition machines (IAS) to the centralized storage server. It can be run directly on the storage server (if it is strong enough) or on a separate compute server, which is connected to the storeage server. 

Following our own need and that of our collaborators (our focus lies on heavy image data like collections 3D confocal stacks) we developed the fsdb as a hands-off data management system for heavy image data. 

Our solution for accessibility of big data is based on __secondary data__, which represent the original data in the form of small (light-weight) derivatives.   

The fsdb is organizing the raw data together with their secondary data strictly by file name in a well structured automatically generated file tree structure. This allows access to all data without a database-specific tools and facilitates working/screening/analyzing of the data with any tool of choice.

The structure of the file system used by the fsdb is defined in the .scripts.config file, which is dynamically generated  in the fsdb's scripts directory. A more detailed description of this file can be found in the dedicated documentation [below](#scriptsconfig).

Documentation on the actions of the shell-scripts of the fsdb are included into a README-section at the head of each of them. An excerpt of these sections can be found [below](#file-specific-documentation-for-the-fsdb).
----


## installation of the fsdb

We are offering two methods for the installation of the fsdb. Both are guiding you through the installation and give you the opportunity to decide, which part of the installtion you want to run - or not. 

# automatic install

The easiest for a stright-forward (de-novo) installation of the fsdb is to clone the repository fsdb-install and run the fsdb-install.sh
```
[git clone  https://gitlab.com/arnimjenett/fsdb-install/-/tree/main](https://gitlab.com/arnimjenett/fsdb-install/-/tree/main)
cd ./fsdb-install
sudo bash fsdb-install.sh
```

# manual install

For a manual installation please download the `initializeFsdb.sh` from the [*install* directory](https://gitlab.com/arnimjenett/fsdb23/-/tree/main/install) of this [project](https://gitlab.com/arnimjenett/fsdb23.git) and run in a terminal using sudo.
```
sudo bash [path to your download directory]/initializeFsdb.sh
```
This will install all necessary Unix tools, download the rest of the fsdb and guide you through the process of installing and configuring your fsdb instance.   

For an update or repair of a pre-existing installation of the fsdb you can run the script `installFsdb.sh` from the local *install* directory. 
```
sudo bash [path to your local installation]/install/installFsdb.sh
```
This will update the scripts of fsdb (from its [gitlab repo](https://gitlab.com/arnimjenett/fsdb23/)) and guide you through the updating process.   

While the fsdb is meant to run in the background (non-interactive) on a Linux server it can - with some limitation - also be run in the 'Windows Subsystem for Linux' (wsl2).

#### preparation of the image acquisition systems (IAS)

The image acquisition systems (IAS), serviced by the fsdb need to make the storage location of the images for the fsdb accessible to the fsdb-server. As most IAS run windows as operating system please refer to the microsoft article [File sharing over a network in Windows](https://support.microsoft.com/en-us/windows/file-sharing-over-a-network-in-windows-b58704b2-f53a-4b82-7bc1-80f9994725bf#ID0EBD&ID0EBD) for the details. For security reasons we suggest to share access to this directory exclusivly with an account you create for this task on the IAS (e.g., fsdbrobot).    
The following information of the IAS will be needed during the setup of the fsdb to facilitate the automatic file transfer:
- IP address of the IAS
- (shared) name of the shared directory
- name of the account used to access above shared directory
- password of above acount

##### file sharing for the fsdb 

On your IAS 
- create a new account to use for the file sharing. 
  - Ensure, that the account name does not contain white-spaces.
- make a note of the password of the new account.

For the root-directory of the storage partition of your IAS
- follow the [online documentation](https://support.microsoft.com/en-us/windows/file-sharing-over-a-network-in-windows-b58704b2-f53a-4b82-7bc1-80f9994725bf#ID0EBD&ID0EBD)on how to created shared directories.
- share the root-directory of the storage partition of your IAS with the newly created account.
  - grant the new account read/write permissions, so it can also clean-up the storage of the microscope.
  
For reasons of hard disk space management we suggest to structure the storage partition of your IAS as follows
IAS (computer)
- storage (partition or hard drive) <-- make this a shared directory
  - user1 (*)
  - user2 (*)
  - user3 (*)
  - ...
  
(*) the names of these directories need to be listed under USER in the configuration of the fsdb (see below).
(**) 

## .scripts.config
```bash
### ==ACCOUNTS==
ADMIN yourAdmin			# <-- sudo-enabled UNIX account
CONSORTIUM yourAssociation		# <-- normal UNIX account
GROUP yourTeam			# <-- UNIX group, which groups the users of a lab
DEV yourDevTeam			# <-- developer accounts have access to the scripts without being ADMIN
DEVACCOUNTS devacc1 devacc2 devacc3	# <-- developers of the fsdb
ADMINACCOUNTS adminacc1 adminacc2 adminacc3	# <-- other system administrators, sudo-enabled 
USERACCOUNTS useracc1 useracc2 useracc3	# <-- list of linux user accounts 
### ==DIRECTORIES==
LAB yourTeamName			# <-- name of the local lab for the file system structure
USER user1 user2 user3		# <-- names of users, space delimited, defining their storage locations on microscopes
### == VARIABLES==
# D and STARTDATE are set dynamically within getVar
DEBUGLEVEL 1			# <-- default debug verbosity level (0: silent, 1:some output, 2:verbose)
HOSTS 127.0.0.1		# <-- allowed hosts for smb.conf, comma-separated

#### MODIFICATIONS BELOW THIS POINT ARE POSSIBLE BUT NOT RECOMMENDED ####
### ==ACCOUNTS==
GROUPACCOUNTS \$ADMIN \$GROUP \$CONSORTIUM \$DEV
### ==DIRECTORIES==
FSDBVERSION=fsdb23			# <-- version number of the fsdb
DATAROOT /DATA				# <-- root of the fsdb
BUPROOT /BUP				# <-- root of the hot backup archive
LABDIR \$DATAROOT/\${LAB}		# <-- all data of a given lab goes into a structured tree, which is rooted here
EXPORTDIR \$DATAROOT/export/\${LAB}	# <-- folder accessible to all labs of the same consortium - within the same network.
STORAGEDIR \$LABDIR/storage	# <-- hidden/protected storage location for raw data
LABDATADIR \$LABDIR/labdata	# <-- lab-accessible location for all data (raw, secondary, tertiary, annotation, ...)
ATTICDIR \$LABDIR/sysdamin	# <-- hidden storage location for the systems administrator 
DUMPDIR \$LABDIR/dump		# <-- intermediate storage location for the clean-up processes
IMPORTS imports				# <-- subfolder in both storage locations; facilitates introduction of other data modalities
ARCHIVEDIR \$LABDATADIR/archive	# <-- output folder for table of content of compressed archives 
EXCHANGEDIR \$LABDATADIR/exchange	# <-- central storage location for lab-interal file-exchange, read-writable for lab members
PROJECTSDIR \$LABDATADIR/projects	# <-- same data as in \$LABDATA; but sorted by projectID
LOGDIR \$WORKDIR/logs		# <-- storage location for the fsdb log files
INDEXDIR \$WORKDIR/index		# <-- storage location for the fsdb index files
SCRIPTSDIR \$WORKDIR/scripts		# <-- storage location for the fsdb scripts
#MACRODIR \$FIJIDIR/macros	# <-- location for the fsdb macros (DO NOT MODIFY)
MATDIR \$WORKDIR/install		# <-- location for installation components
TEMPLATESDIR \$MATDIR/templates	# <-- location for configuration file templates

### ==MAIN CONFIGURATION==
# DO NOT EDIT THE MAIN CONFIGURATION FILE AS IT WILL BE COMPLETELY OVERWRITTEN 
# AS SOON AS A SUB-CONFIGURATION FILE IS MODIFIED
CONFIG \${SCRIPTSDIR}/.scripts.config

## ==external softwares==
FIJIDIR \$SCRIPTSDIR/Fiji.app	# <-- location of the integrated instance of fiji
ONLINEDOC https://gitlab.com/arnimjenett/fsdb23#installation-of-the-fsdb

### ==FILES==
LOGO \$SCRIPTSDIR/logo.png	# <-- storage location of the lab's logo for integration into the movies

### ==CENTRALLY DEFINED PARAMETERS==
permissibleAgeOfIndex 360	# <-- used in makeIndex to prevent rewriting a recently written index
TIMEOUTMINUTES 30		# <-- time in minutes allowed for all secData-generation processes (per raw dataset).


# ==> Modify values below in /mnt/c/Users/teforadmin/tps/gitlab/fsdb23/scripts/core/core.config <==
# ==fsdb core functions==
CORENAME core
COREDIR $SCRIPTSDIR/core
COREMACROS $MACROSDIR/fsdb.core

# ==CORE SCRIPTS==
MAKEINDEX $COREDIR/makeIndex.sh
MAKEFSDBINIT $COREDIR/makeFsdbInit.sh	# <-- translates the label/value-pairs of scripts.config into ij.Prefs for use in fiji
FIJIONSERVER $COREDIR/fijiOnServer.sh
COMPLISTS $COREDIR/compareLists.sh		# <-- compares the fist column of two lists (files)
UPDATEFSDB $COREDIR/updateFsdb.sh		# <-- updates the fsdb from online repo
UPDATEMACROS $COREDIR/updateMacros.sh		# <-- updates fsdb-macros from import location to active location (FIJIDIR)
POPVARS_SCR $COREDIR/populateVarsInMacro.sh 	# <-- populates/updates fsdb-variables within macros
POPVARS_FUN $COREDIR/getFsdbVars_fun.txt      # <-- transplantable function used by POPVARS_SCR

# functional (helper) core macros
INITLOG_FMAC $COREMACROS/fsdb.core.initLOG.ijm
DEBUG_FMAC $COREMACROS/fsdb.core.logger.ijm
MAKEDIR_FMAC $COREMACROS/fsdb.core.makeDirRecursively.ijm
TIMESTAMP_FMAC $COREMACROS/fsdb.core.ts.ijm
# the following initially does not exist but is dynamically created by MAKEFSDBINIT
INITFSDB_FMAC $COREMACROS/fsdb.core.initFsdb.ijm

### == VARIABLES==
STACKEXTENSION nd2 lif 			# <-- expandible list of treated file extension (currently possible values: nd2 czi lif)


# ==> Modify values below in /mnt/c/Users/teforadmin/tps/gitlab/fsdb23/scripts/sdg/sdg.config <==
### ==CONFIGURATION FOR THE FSDB SECONDARY DATA GENERATOR==
# ==secondary data generation==
SECDATANAME sdg
SECDATADIR $SCRIPTSDIR/$SECDATANAME
SECDATAMACROS $MACROSDIR/fsdb.$SECDATANAME

### ==TOGGLES FOR SECONDARY DATA TYPES==
MIP_TOG 1					# <-- generates a maximum intensity projection and saves it as png
AIP_TOG 1					# <-- generates a average intensity projection and saves it as png
CS_TOG 1					# <-- extracts the slice in the middle of the stack
TRANS_TOG 0					# <-- turns each slice into a frame of its output mp4
HD5_TOG 0					# <-- saves in hdf5 format for BigDataViewer
SUBSTACK_TOG 0				# <-- generates a stack of substack projections (extened focus)
NRRD_TOG 0					# <-- separates cahnnels and saves them in individual (compressed) nrrd files.
MHA_TOG 0					# <-- separates cahnnels and saves them in individual mha files.
### ==TOGGLES FOR IMAGE PRE-PROCESSING==
GLOBAL_PPTOG 1				# <-- toggles ALL image-pre-processing on/off (main-switch)
COLCORR_PPTOG 1				# <-- adjusts the colomaps (for all channels) to the TPS-defaults
CROPSTACK_PPTOG 0			# <-- reduces file size by cropping to specimen
UNMIX_PPTOG 0         # <-- reduces bleedthrough of ref-chan by subtraction of ref-chan from sig-chan
### ==TOGGLES FOR IMAGE PROCESSING==
NOOPT HD5 TRANS NRRD		# <-- surpresses image processing for listed output types #TODO: check if still valid
GLOBAL_IPTOG  1				# <-- toggles ALL image-processing on/off (main-switch)
OPTIMIZECONTRAST_IPTOG 1	# keep this first in the list of IPTOGs! <-- runs "Enhance Contrast", "saturated=0.1"
SETCONTRAST_IPTOG 1			# <-- sets the dymanic range to the max (0-255/4095)
CLAHE_IPTOG 0				# <-- runs 'contrast limited adaptive histogram equalization' (sophisicated contrast enhancement)
### ==TOGGLES FOR IMAGE ANNOTATION==
GLOBAL_IATOG 1				# <-- toggles ALL image-annotation on/off (main-switch)
WRITECONTRAST_IATOG 1		# <-- writes the minimal and maximal displayed values into the secData (for each channel)
WRITESCALEBAR_IATOG 1		# <-- writes a scalebar into the secData (only meaningful with calibrated data)

### ==SUFFIX FOR OUTPUT DIRECTORY==
SECDATA_EXT -secData
### ==SUFFIXES FOR FILE TYPES==
MIP_SUFF .mip
AIP_SUFF .aip
CS_SUFF .cs
TRANS_SUFF .trans
HD5_SUFF .bdv
SUBSTACK_SUFF .sss
NRRD_SUFF .cmp
MHA_SUFF .cmp
### ==SUFFIXES FOR IMAGE PRE-PROCESSING==
COLCORR_PPSUFF -cc
CROPSTACK_PPSUFF -crp
### ==SUFFIXES FOR IMAGE PROCESSING==
SETCONTRAST_IPSUFF .sc
OPTIMIZECONTRAST_IPSUFF .oc
CLAHE_IPSUFF .cl
### ==SUFFIXES FOR IMAGE ANNOTATION==
WRITECONTRAST_IASUFF .wc
WRITESCALEBAR_IASUFF .sb
### ==FILE TYPES FOR SEC DATA==
MIP_FT .png
AIP_FT .png
CS_FT .png
TRANS_FT .mp4
HD5_FT .h5
SUBSTACK_FT .tif
CROPSTACK_FT .tif
PREPROC_FT .tif
NRRD_FT .nrrd
MHA_FT .mha

#### DO NOT MODIFY BELOW THIS POINT ####
### ==SCRIPTS==
# ==sedcondary data generation==
SECDATAGEN $SECDATADIR/runner.sh
MAKEMETA $SECDATADIR/writeMetadata.sh
MAKECALLER $SECDATADIR/makeCaller.sh
MAKESECDATADIR_SRC $SECDATADIR/makeSecDataDir.sh
PNG2MOV $SECDATADIR/ffmpeg-png2mp4.sh	# on old systems: avconv-png2mp4.sh, otherwise ffmpeg-png2mp4.sh
REAPER $SECDATADIR/reaper.sh	# <-- stops all active secondary data generation tasks

### ==MACROS==
# wrapper macros
CALLER $SECDATAMACROS/caller.ijm
INITIMAGE $SECDATAMACROS/fsdb.sdg.initImage.ijm

# secData generating macros
MIP_MAC $SECDATAMACROS/fsdb.sdg.mip.ijm
AIP_MAC $SECDATAMACROS/fsdb.sdg.aip.ijm
CS_MAC $SECDATAMACROS/fsdb.sdg.cs.ijm
TRANS_MAC $SECDATAMACROS/fsdb.sdg.translation.ijm
HD5_MAC $SECDATAMACROS/fsdb.sdg.hd5.ijm
SUBSTACK_MAC $SECDATAMACROS/fsdb.sdg.substackstack.ijm
#NRRD_MAC $SECDATAMACROS/fsdb.sdg.nrrd.ijm

# image processing macros
SETCONTRAST_MAC $SECDATAMACROS/fsdb.sdg.setContrast.ijm
OPTIMIZECONTRAST_MAC $SECDATAMACROS/fsdb.sdg.optimizeContrast.ijm
CLAHE_MAC $SECDATAMACROS/fsdb.sdg.clahe.ijm
CROPSTACK_MAC $SECDATAMACROS/fsdb.sdg.cropStackAutomatic.ijm
COLCORR_MAC $SECDATAMACROS/fsdb.sdg.correctColors.ijm

# image annotation macros
WRITECONTRAST_MAC $SECDATAMACROS/fsdb.sdg.writeContrast.ijm
WRITESCALEBAR_MAC $SECDATAMACROS/fsdb.sdg.writeScalebar.ijm

# functional (helper) macros
SDGFUNCTIONS $SECDATAMACROS/fsdb.sdg.secDataFunctions.ijm


```
---
## file-specific documentation for the fsdb    
(in alphabetical order)
---
### archiver :: compress

This script is compressing the folder provided as input.
if the input is a file ...?
	strip and compress folder or compress file??

This script expects input like this:   
`$ find /DATA/tcf/labdata/imports/ -type d |grep secData |sed \'s@secData.*@secData@\' |sort -u |tee 180801.imports.secData.dirs`

This script expects the following parameters    
Usage: $0 [-i inBaseDir] [-o outBaseDir] [-h] absolute-paths

-i	inDirBase
		This is the left part of the input path, which is to be trucated

-o	outDirBase
		This is the base of the output path. The inDirBase will be replaced
		by this string. If empty, the default value will be used instead.
		Default value is $defaultOutDirBase

-h	help
		Displays this help.
		

---
### archiver :: compressor

This script is the wrapper of the controlled compression process from raw data to 
the hot archive. 

This script (and the scripts within) is employing the following scripts:
- compressProject.sh
	compresses individual files or directories into a compressed archive (tar.7z)
	in $BUPROOT. Before going to work on the compression This script employs 
	writeChecksum.sh on the provided file or directory. 
- writeChecksum.sh
	writes md5 checksums for individual files of the entire content of a directory 
	into a structured flat text file. 
	For individual files, this file has the same name as the input file with the 
	added extension .md5.checksum.
	For directories the output file is simply calledmd5.checksums and is located 
	inside of the analysed directory.
- rewriteToc.sh
	writes a table-of-contents for the compressed archive and stores it in a 
	flat text file with the same name with the added file extension .toc
- testChecksum.sh
	compares the md5 checksums of the arcived files with the original files. 
	For this this script is extracting ( decompress and detar) the archive and 
	runs wrtieChecksums.sh on the output. The resulting files containing the md5 
	checksums of the decompressed files is then compared to the file containing 
	the md5 checksums of the files before compression. When both lists are 
	(nearly) identical, the (raw-)data can be discarded. 
- compareLists.sh <-- $COMPLISTS
	compares two lists.
	
All of these scripts are sourcing paramChecksum.sh
This yields the following variables:
	- suffix : the file name extension of the compressed archive (by default tar.7z)
	- isDir : boolean, which is indicating, if $inPath is a directory (yes=1)
	- inPath : derived from $1
	- inPathBase : dirname $inPath
	- inPathTrunc : $inPath minus $inPathBase
	- outPathBase : same as $inPath, however, $DATAROOT is replaced by $BUPROOT
	- outTar : tar is used to maintain permissions and modification/access times
	- outFile : the compressed archive.
	
As part of the fsdb this script is sourcing getVar.sh
This yields all variables defined in $SCRIPTSDIR/.scripts.config ($CONFIG)


---
### archiver :: compressProject

This script is compressing the folders in $PROJECTSDIR into tar.7z archives. 
These archives are labeled with the corresponding projectID and stored at $BUPROOT

This script expects the projectID of the project,which shall be compressed as only parameter.
$1= projectID (e.g. SB-124-DR)

tar is used because it does preserve the permissions, which otherwise (7z only) would get lost

As part of the compression suite this script is sourcing paramChecksum.sh.
This yields the following variables:
	- suffix : the file name extension of the compressed archive (by default tar.7z)
	- isDir : boolean, which is indicating, if $inPath is a directory (yes=1)
	- inPath : derived from $1
	- inPathBase : dirname $inPath
	- inPathTrunc : $inPath minus $inPathBase
	- outPathBase : same as $inPath, however, $DATAROOT is replaced by $BUPROOT
	- outTar : tar is used to maintain permissions and modification/access times
	- outFile : the compressed archive.
	
As part of the fsdb this script is sourcing getVar.sh
This yields all variables defined in $SCRIPTSDIR/.scripts.config ($CONFIG)

--> https://stackoverflow.com/questions/12313242/utilizing-multi-core-for-targzip-bzip-compression-decompression


---
### archiver :: compressRawData.365

This script compresses all raw data sets, which are older than one year (365 days)
into individual tar.7z archives.



---
### archiver :: compressRawData

This script is compressing individual raw data sets into the same directory as the original data. 

This script expects the path to a single uncompressed raw data set as first parameter

tar is used because it does preserve the permissions, which otherwise (7z only) would get lost

As part of the compression suite this script is sourcing paramChecksum.sh.
This yields the following variables:
	- suffix : the file name extension of the compressed archive (by default tar.7z)
	- isDir : boolean, which is indicating, if $inPath is a directory (yes=1)
	- inPath : derived from $1
	- inPathBase : dirname $inPath
	- inPathTrunc : $inPath minus $inPathBase
	- outPathBase : same as $inPath, however, $DATAROOT is replaced by $BUPROOT
	- outTar : tar is used to maintain permissions and modification/access times
	- outFile : the compressed archive.
	
As part of the fsdb this script is sourcing getVar.sh
This yields all variables defined in $SCRIPTSDIR/.scripts.config ($CONFIG)


---
### archiver :: decompress

This script is decompressing the tar.7z provided as first parameter

Parameters:
$1 : full path to *.tar.7z archive

This script expects input like this:
teforadmin@celph-gif:~$ find /BUP/tcf/labdata/imports/ -type f -name "*.tar.7z
A standard call can be as follows:
teforadmin@celph-gif:~$ for i in $(find /BUP/tcf/labdata/imports/ -type f -name "*.tar.7z); do bash $0 -i "/BUP" -o "/DATA" $i; done

This script expects the following parameter
Usage: $0 [-i inBaseDir] [-o outBaseDir] [-h] absolute-paths

-i	inArchBase
		This is the left part of the input path, which is to be trucated
		If this is not 

-o	outDirBase
		This is the base of the output path. The inArchBase will be replaced
		by this string. If empty, the default value will be used instead.
		Default value is $defaultOutDirBase

-h	help
		Displays this help.

for decompression check https://askubuntu.com/a/341636
--> 7z x -so yourfile.tar.7z | tar xf - -C target_dir

---
### archiver :: make4TBpackages

This script is building bundles of a given size (currently 4TB for storage on
cold storage disks)

This script can take (optionally) a options.
[-f file list]
[-s bundle-size]
[-p input-path]
[-h]


---
### archiver :: paramChecksum

This script is meant to be sourced.

It is providing the following variables:
	- suffix : the file name extension of the compressed archive (by default tar.7z)
	- isDir : boolean, which is indicating, if $inPath is a directory (yes=1)
	- inPath : derived from $1
	- inPathBase : dirname $inPath
	- inPathTrunc : $inPath minus $inPathBase
	- outPathBase : same as $inPath, however, $DATAROOT is replaced by $BUPROOT
	- outTar : tar is used to maintain permissions and modification/access times
	- outFile : the compressed archive.

... to the following scripts:
- compressProject.sh
- writeChecksum.sh
- testCheckSum.sh

Since it shall be sourced it does NOT need any parameters.

Prerequisits: 
- tar
- 7z


---
### archiver :: permutate365



---
### archiver :: permutate365withoutUpdate



---
### archiver :: rewriteToc

This script is writing the table of content (TOC) of .tar.7z files for the
fsdb-system.

The script expects the following parameters:
$1 full path to a .tar.7z-archive
[$2 optional the ouptut path for the TOC. Default is the same directory as $1]
[$3 toggle to keep the intermediate tar. Default=0 --> remove intermediate files]

The output is a flat text file with the suffix .tar.7z.toc in the same directory
as the input archive.

The content of the TOC is formatted by tar, which results in e.g.
-rw-rw-r-- teforadmin/teforadmin  9310 2018-08-01 16:54 compressionDummy/pattern-160906Ed_575j_7d-la_MS-16-DR_256_test.xy.0174.png
This can be matched from a uncompressed folder by
ls -dl --time-style="+%Y-%m-%d %H:%M" $(find $($inDir))| sed "s@$inDirBase/@@" | awk \'{print $1" "$2"/"$4" "$5" "$6" "$7" "$NF}\'
Where
  ls -dl --time-style="+%Y-%m-%d %H:%M" $(find $($inDir))
    --> provides a list of file-descriptors in long format with the time format
      as defined by tar (%Y-%m-%d %H:%M)
  | sed "s@$inDirBase/@@"
    --> strips the $inDirBase off the path. E.g. the input path ($1) of the folder
      containing the above example was /CACHE/compressionDummy
    (The inDirBase is a high-level path (the root directories) of the input path,
      which is excluded (trucated) in the tar-process to facilitate reconstitution
      of these archives into arbitrary positions.)
  | awk \'{print $1" "$2"/"$4" "$5" "$6" "$7" "$NF}\'
    --> reformats the data of the above ls-argument following the template of tar.


---
### archiver :: usbHddDock

This script guides the user through the process of formatting and partitioning a new harddrive for the use as cold-storage-drive.
It is doing this with the following steps:
  * searching the system for storage devices
  * categorizing all found devices in \'used\' and \'un-used\'
  * displaying the list of devices and waiting for user input
  * formatting and partitioning the specified device
    * (carefully)
  * mounting the freshly formatted partition
  * displaying all mounted drives and their available volumes (df -h)

This script can accept one paratmeter:
$1 = [ alternative file system type (default ext4) ]


---
### archiver :: writeChecksum

This script is creating a file (md5.checksum) in which it writes the md5-checksum 
for each file of the directory, which is provided as parameter.

This script expects the absolut path to the directory, which files shall get checksummed.
$1 = path to directory
$2 = forces rewrite of all md5 checksums if set to \'force\' 
#$3 = alternative output directory [DEPRECATED]

As part of the compression suite this script is sourcing paramChecksum.sh.
This yields the following variables:
	- suffix : the file name extension of the compressed archive (by default tar.7z)
	- isDir : boolean, which is indicating, if $inPath is a directory (yes=1)
	- inPath : derived from $1
	- inPathBase : dirname $inPath
	- inPathTrunc : $inPath minus $inPathBase
	- outPathBase : currently hardcoded to $BUPROOT
	- outTar : tar is used to maintain permissions and modification/access times
	- outFile : the compressed archive.

As part of the fsdb this script is sourcing getVar.sh
This yields all variables defined in $SCRIPTSDIR/.scripts.config ($CONFIG)


---
### archiver :: writeToColdArchive

This script writes the files of the provided list (bundle) to a cold-archive-disk.

It expects one parameter:
$1 = bundle file, which is a list of asolute paths to the files to be written.

This script is integrated into the fsdb by getVar. 


---
### core :: compareLists

compareLists.sh; formerly known as tcf_runLISTagainstLIST.sh
This script compares two lists of identical elements using \'sort\' and \'diff\'.
INPUT:
$1 = first list.
$2 = second list.
[$3] = debug level. can be empty. by default chatty (1).

OUTPUT:
three files in /tmp/.
names are constructed from
- the current date (format yymmdd)
- the basename of the first list
- the basename of the second list
- the string "only1", "only2" or "both"
- file extension: .txt

underlying concept:
- from two lists find and store in separeate lists the elements, which are only 
in one (or the other) of the lists or in both of them.

mode of function:
- isolate first column of input lists --> C1 
- sort C1 --> C1.sorted
- run a diff on the two C1.sorted
- separate the diff-output into three different files (on the basis of diff\'s annotation (<, >)

note: 
- the input data are treated as space-delimited tables.
- only the first column of the input data will be taken into account by this script.


---
### core :: fijiOnServer

This script is a wrapper to run fiji headlessly.
It was build to run scripts of the fsdb secDataGeneration directly on a headless storage or compute server. 
It expects two parameters as input:
$1 = absolute path to the macro to be run
$2 = absolute path to the image to work with

For macros, which have a build-in image-opening-mechanism the order can 
also be reversed ($1:macro; $2:image), which provides the image as a 
parameter to the macro (e.g. caller.ijm).

For running on the storage-server (headless) this script is using the 
helper-wrapper xvfb-run-safe.sh, which makes sure, that there is no 
screen-clash when this is run in multiple instances at the same moment.
xvfb-run-safe.sh searches for a non-used screen before starting fiji.
xvfb-run-safe.sh must be located in the same folder as this script.

Other computers run fiji interactively as $ADMIN .


---
### core :: fun_colMsg

completely independent script for the colorization of outputs.
this script should be sourced by the script, which needs to colorize its output.

This script provides the following output (color) modes:
error:		error <-- white on red background, new-line
message:	msg <-- green, no new-line
warning:	warn <-- red, new-line
debug level 1-3: dbg, dbg1, dbg2	<-- magenta
introduction:	intro <-- cyan, new-line
permissive interrupt: interPerm <-- green, new-line, by default \'yes\'
restrictive interrupt:	interRest <-- red, new-line, by default \'no"

Alternative default colors:
Foreground colors
39	Default foreground color
30	Black
31	Red
32	Green
33	Yellow
34	Blue
35	Magenta
36	Cyan
37	Light gray

Background colors
49	Default background color
40	Black
41	Red
42	Green
43	Yellow
44	Blue
45	Magenta
46	Cyan
47	Light gray

:: from https://misc.flogisoft.com/bash/tip_colors_and_formatting


---
### core :: getVar

This script is getting the values from the central configuration file ( $SCRIPTSDIR/.scripts.config ($CONFIG) ) 
and passses them to the sourcing script.

For the directories, which are defined in .scripts.config (variable-name ends on
\'DIR\') mkdir -p is run to make sure, that these directories really exist.

This script needs to be called via \'source\'.

underlying concept:    
- for some variables all scripts of the fsdb need to work with identical values
- for differentiating these from \'local variables\' the \'golbal variables\' are 
	CAPITALIZED.
- \'global variables\' are defined in the .scripts.config file.
- form of the .scripts.config file:   
-- first column: name of \'global variable\'   
-- second column: name of application using/introducing this variable   
-- third column to end of line: value(s) of the \'global variable\'   
To be on the save side columns are separated by the string " | " (space-pipe-space).

mode of function:   
- make sure, .scripts.config does exist. Create, if not.
- for each line in .scripts.config \'associate\' the first word with the rest of 
	the line (export/source)
- for each directory, defined in .scripts.config, make sure, that is does exist 
	(mkdir -p)

debugging level:   
The verbosity of the debugging output can be set globally and locally, where the 
local setting is always overwriting the global one.   
0 - silent   
1 - some output   
2 - verbose   
3 - very verbose   

The global debugging level is defined by the first parameter to the sourcing of 
 fun_colMsg.sh
The local debugging level is set (for each script individually) by the variable 
 \'debug\', which also can have the same values as the global levels (0-3)
	
Aside of ALL VARIABLES DEFINED IN .scripts.config this script explicitly exports/
populates the following variables:
- D : timestamp of today in YYMMDD
- STARTDATE : same as $D but in contrast to $D this will not be updated at midnight. 
	STARTDATE is used to keep referencing the $INDEX of the starting day even 
	if/while the process is running longer than midnight.
- SCRIPTSDIR : directory, which is containing all (shell) scripts of the fsdb.
- WORKDIR : the root-directory of the fsdb

--> machine-specific configurations
- COMP : name of the computer this script is running on 
- maxsize : maximal file size that can be handled on this machine
- minsize : minimal filesize to b handled by this machine
- ORDER : sorted order of file list 
	(by default youngest first(\'age\'), on big machines biggst first (\'size\'))
- FIJIONSERVER : potentially overwrites which script is used to run the 
	secData-Generator


---
### core :: makeFsdbInit

This script translates the label-value-pairs of .scripts.config into ij.Prefs
by creating the macro initFSDB.ijm in the macros directory. 

The initFSDB.ijm is used by the macros of the fsdb to read-in the values of .scripts.config.


---
### core :: makeIndex

This script is listing the content of $LABDATADIR and $STORAGEDIR and extracts 
todo-lists for the secondary data generation.

This script does not need any parameters however the following parameters can be 
provided:  
   
	-p	project
			This is a limiting string, which is included in the \'find\' command
			Setting this will limit the population of files to files, whose filenames 
			include this string.

	-o	order of sorting
			valide values: 
			- \'age\' : youngest file first (default)
			- \'size\' : biggest file first (useful on strong machines only)

	-f	force index generation
			Setting this parameter forces the index-generation, even if the pre-existing 
			index is younger that the age-limit.

	-h	help
			Displays this help.

	absolute-paths
			This is the absolute path to the directory, which is supposed to be indexed. 

underlying concept:
- because searching the file system (especially in large data compilations) for 
every step would be excruiatingly slow, the fsdb is running this indexing system
(at least once per day by cron-job or on demand, if today\'s indices do not exist, yet).
- queries (grep) on the resulting index-files are significantly faster, than the
alternative (find).
- since many of the specimens in question are too big for acquisition in a single 
field-of-view, they are imaged in tile-scan. The results are saved in two data 
sets: tiles (rawest form) and merged (tiles stitched together into one file). 
High resolution images with only one tile may be stored with the suffix \'stack\' 
and are treated like merged images.

TODO: implement search on $PROJECTSDIR ?


---
### core :: makeTodoList---
### core :: populateVarsInMacro---
### core :: removeFromFsdb

This script removes the files, which are matching the input string from the fsdb.

This script expectes as parameter a searchstring   
$1 [ search string]

optionally the option -a can be given, which triggers automatic execution - no 
confirmation by the user.

---
### core :: removeRawDataFromFsdb

This script removes the raw data (only) from inputPath.


---
### core :: updateFsdb

This script is updating the fsdb by pulling the scripts from the online repository
and updating the macros in their active locations 

no parameter needed


---
### core :: updateMacros

This script is updating the fiji macros from their import loactions (e.g., fsdb/core/Fiji.app/macros/...) 
with the active location (fsdb/Fiji.app/macros/fsdb.core/...)

no parameter needed


---
### installation :: newAccount

This script creates a new user on the fsdb, put it in the correct groups, and 
sets-up a SMB account so it can access remotly to the labdata folder.

---
### janitor :: cleanDump

This script is deleting data, which is older than 180 days, from the $DUMPDIR  

This script is part of the janitor-job

mode of function:
- find in $DUMPDIR all files older than 180 days and remove them.
- find in $DUMPDIR all empty folders (relicts of cleanup) and remove them.

---
### janitor :: cleanExchange

This script is cleaning the $EXCHANGEDIR 
It moves everything older than 30 from $EXCHANGEDIR into the $DUMPDIR

This script is part of the janitor-job

mode of function:
- find all files in $EXCHANGEDIR, which are older than 30 days
- generate corresponding directory in $DUMPDIR
- move these files to $DUMPDIR
- delete remaining empty folders from $EXCHANGEDIR


---
### janitor :: cleanImports
<< README
This script generates hard links between the original data in the protected 
location ($STORAGEDIR/$IMPORTS/) and the accessible location ($LABDATADIR/$IMPORTS) 
and vice versa.

All variables are defined in the configuration file which is defined in getVar.sh

mode of function
- this script expects raw data (see $STACKEXTENSION) in the $USERs folder at 
$STORAGEDIR/$IMPORTS/.
- it generates a corresponding folder at e.g., $LABDATADIR/$IMPORTS 
and creates a hard link for the raw data set within that folder.
- subsequently it does the same in reverse: synchonizing the raw data in 
$LABDATADIR/$IMPORTS with $STORAGEDIR/$IMPORTS
- last but not least it makes sure, that the permission settings for the $IMPORTS 
folders are correct.


---
### janitor :: cleanLocks
<< README
This script is removing the lock files - which were generated during the 
secondary data generation (runner.sh). 

Only lock files older than 1 day are removed. 


---
### janitor :: cleanTmp

This script removes all files, which belong to the user-group root or 
$ADMIN and are older than 2 days from the tmp-directory. It also removes 
everything older than 2 days from  $LOGDIR and $INDEXDIR as well as the 
file \'debugger\' from $MACROSDIR. 

Should there be empty directories left over after the file-removal, these will
be removed as well.

This script is part of the janitor-job

mode of function
- find and remove all files older than 2 days from $LOGDIR and $INDEXDIR
- remove debugging-notes (debugger) from $MACROSDIR
- find and remove all files older than 2 days from /tmp, as long as it belongs 
to \'root\' or $ADMIN


---
### janitor :: fixLinks


This script controls, if the files (raw data only) in $LABDATADIR and $STORAGEDIR 
are links, not copies, by comparing their inodeIDs, relative paths and file size.

This script expects two parameters:
[$1] = force rewrite of indices (0/1; default 0)
[$2] = SEARCHSTRING; if entered this string is limiting the execution of this 
script to files with $SEARCHSTRING in their filename



---
### janitor :: fixPermissions

For making sure, that the files are accessible and protected as intended, this
script is (re-)setting the permissions on the fsdb file system and the contained
files.

This script is part of $CLEANIMPORTS

This scripr accepts one optional parameter: 
[$1] = path to the directory which permissions need to be fixed

underlying concept:
- each original data set has two \'pointers\', which earlier were gernerated using \'ln\'. 
-- one in $STORAGEDIR/$IMPORTS, the other in $LABDATADIR/$IMPORTS, at the corresponding location.
- data at $LABDATADIR/$IMPORTS are user-writeable (770) and by this endangered by destruction/deletion.
- $STORAGEDIR/$IMPORTS and the data within is read-only and inaccessible for standard users.
- if original data is accidentially removed from $LABDATADIR/$IMPORTS, this script reconstitutes it from $STORAGEDIR/$IMPORTS. 

mode of function:
- set permissions for $LABDATADIR/$IMPORTS/ to 770
- set permissions for $INDEXDIR/ to 770
- set permissions for $STORAGEDIR/$IMPORTS/ to 750

---
### janitor :: janitor

This script is a simple wrapper for other scripts, which are cleaning up the fsdb.

This cleaning mechanism is broken into multiple scripts to give the systems
administrator the opportunity of running them also separately through individual
cron-jobs or manually.


---
### janitor :: makeProjectLinks
<< README
This script is creating a directory for each projectID at $PROJECTSDIR and links 
all folders of that project from $LABDATADIR into $RPOJECTSDIR

Parameters:
$1 can optionally be 1, which forces the index-generation, even if it normally 
would be skipped, because the index is too young.  


---
### janitor :: removeLifext

This script removes the Leica lifext-files, which are generated automatically by the LASX software.


---
### sdg :: avconv-png2mp4

provide first (any) frame of movie (something.0000.something_else.suffix)
frames need to be numbered with 4 leading zeros. the numbering can be anywhere within the file name and can be prefixed
the numbering must be followed by a puctuation sign (.-_)
$2: optionally a height in pixels of the movie can be provided
$3: frame rate; default 24fps
$4: optionally a boolean can trigger overwrite (default 0)
$5: optionally a boolean can trigger the logo (default 1)


---
### sdg :: ffmpeg-png2mp4

This script converts a series of numbered pngs into a movie in mp4 format.

mode of function and prerequisits
Provide first (or any) frame of movie (something.0000.something_else.suffix)
frames need to be numbered with 3 leading zeros (e.g.0001).
The numbering can be anywhere within the file name and can be prefixed with any string.
The numbering must be followed by one of the folllowing puctuation signs (.-_)
$2: optionally a height in pixels of the movie can be provided (e.g. 720 for results in 720p)
$3: optionally a frame rate; default 24fps
$4: optionally a boolean can toggle overwrite (default 0)
$5: optionally a boolean can toggle the insertion of a logo (default 1)
$6: overlay string in lower-left corner; (default 0)

If $5 is set to 2 this script will ask for the location of the logo to be overlayed.

Requirements:
ffmpeg, imagemagick


---
### sdg :: makeCaller

This script is writing dynamically the wrapper macro for the secondary data generation in fiji. 
The wrapper is desinged in a way, that it produces only the missing seondary data. 

This script expects the following variables:
$1 = basename or full name of the image to be treated
[$2] = optionally the series number - by default 1
[$3] = optionally the date ($D, yymmdd) of the todo lists, which are used in this process
[$4] = optionally $INDEXDIR can be defined on the command line
For images with more than 1 series the parameters $2 and $3 are mandatory. Therefore it is good practice to always provide them. 

underlying concept:
- based on the indices in $INDEXDIR write a fiji macro, which will generate the missing secData.
- The indices in $INDEXDIR are generated by makeIndex.sh beforehand.

mode of function:
- check, which modalities of secondary data (secData) are missing
- write wrapper (caller.ijm), which is generating missing secData when run in fiji.

TODO: implement getopts as in makeIndex.sh

---
### sdg :: makeSecDataDir

This scritps is meant to be soureced by scritps of the sencondary data generation.
It defines and created (on the basis of the input file) the output directory for secData.

If the absolute path to the image in $1 already contains the string defined by 
SECDATA_EXT in sdb.config the output will be written into the same directory.

Parameters:
this script expects the absolute path to the image.   
$1: absolute path to image

This script populates and exports the variables:
- image        <-- the absolute path to the image
- stacktype    <-- the type-defining filename extension; e.g., tif
- imageBn      <-- the basename of the image (without path, without extension)
- outPath      <-- absolute path to the secData-directory (output directory)

---
### sdg :: reaper

This script is ending the processes of the secondary data generation by 
killing the involved processes:

mode of function:
find the processIDs and use them in a \'kill -9\' for
- runSecDataGeneration.sh
- fijiOnServer.sh
- everything with the string \'Fiji\' in it.


---
### sdg :: runner

This script is running all necessary steps for the secondary data generation.

parameters: 
$1 : if not-empty this parameter is limiting the generation of a todo-list to the files containing the string. 
	
underlying conept:
- find missing secondary data by comparing the list of raw data with the lists of secondary data modalities.
- generate and run fiji wrapper-macro, which generates missing secondary data

mode of function:
- read in all globally defined variables from $CONFIG file <-- source $thisDir/../core/getVar.sh
- mount all needed drives
- generate log-files
- kill all earlier instances of this script and cleanup loose ends
- generate indices of all data (originals and secData), this includes the generation of a todo-list
- permutate through the todo-list, generate missing secondary data
-- read out metadata (bftools, exiftools) <-- $MAKEMETA
-- write wrapper-macro specific for the needs of the current image (makeCaller.sh --> Fiji.app/macros/fsdb.sdg/caller.ijm)
-- call fiji with caller.ijm and image, which generates the secondary data by calling the following macros: <-- $FIJIONSERVER $CALLER $rawImage
--- maximum intensity projection (mip, mipopt) <-- Fiji.app/macros/fsdb.sdg/fsdb.sdg.mip.ijm
--- average intensity projection (aip, aipopt) <-- Fiji.app/macros/fsdb.sdg/fsdb.sdg.aip.ijm
--- center slice of the stack (cs, csopt) <-- Fiji.app/macros/fsdb.sdg/fsdb.sdg.cs.ijm
--- 3D-representation in the form of a pyramidal hdf5 (h5) <-- Fiji.app/macros/fsdb.sdg/fsdb.sdg.hd5.ijm
--- preparation of heavily compressed movie represenations: slices -> 2Dimages (png) <-- Fiji.app/macros/fsdb.sdg/fsdb.sdg.translation.ijm
--- sss (TODO: under construction)
(all fiji macros are located within fsdb.sdg-directory within the macros folder of the fiji instance included within the fsdb (fesb/scripts/Fiji.app/macros/fsdb.sdg)
-- convert png-series for movies into movies (mp4) <-- $PNG2MOV

tested on:
- lif, nd2, czi: 3D, 2D, multi-channel, single-channel

prerequisits:
exiftool
- install: sudo apt-get install -y exiftool



---
### sdg :: updateSdg.dbg

DEBUGGING SCRIPT
this script displays the ij.Prefs.get in all macros in comparison to the ij.Prefs.set in $COREMACROS/fsdb.core.initFsdb.ijm

purely manual. Ecxept for $SECDATAMACROS/fsdb.sdg.vars.txt no changes are applied.

---
### sdg :: writeMetadata

This script is writing a metadata extract from the provided image file into the location of the image:
bash thisScript /somedir/image --> /somedir/imageBn.meta.txt

This script expects one parameter:
$1 = absolute path to image to be analyzed.

DEPENDENCIES: 
exiftool are installed automatically
--> https://www.sno.phy.queensu.ca/~phil/exiftool/#system
bftools are expected in $SCRIPTSDIR/bftools
--> https://docs.openmicroscopy.org/bio-formats/latest/users/comlinetools/index.html


---
### transfer :: fetchDataFromMicroscopes

This script is transferring original data from the acquisition instruments to the 
storage server ($STORAGEDIR/$IMPORTS), generates links to $LABDATADIR/$IMPORTS and 
cleans up the acquisition instrument\'s storage space 

mode of function:
- connect to the microscope computers <-- $SCRIPTSDIR/$MOUNTMICS
- copy all files, which are older than ten minutes to the corresponding location on the server <-- parallel rsync
- remove transferred files from the microscope computer
- on the storage server, move data into corresponding -secData folders at $STORAGEDIR/$IMPORTS
- generate hard links to $LABDATADIR/$IMPORTS
- reconfirm that all links exists between $STORAGEDIR/$IMPORTS and $LABDATADIR/$IMPORTS <-- $SCRIPTSDIR/$CLEANIMPORTS
- start secondary data generation in the background --> $SCRIPTSDIR/$SECDATAGEN &

attention:
Long lasting image acquisitions (e.g. Leica HCS) are often stored in many small image files. 
This may result in incomplete transmission of the currently active scan. 
The transfer of that scan will be completed as soon as this script is run again - after the scan is complete.


---
### transfer :: mountMicroscopes

This script mounts given microscopes to the server it is running on.

It expects three parameters:
$1 = IP address of the computer to be connected to
$2 = name of the remote directory to be mounted
$3 = mount point on the local system

comments/explanations on the mount command 
from man mount at
https://www.samba.org/~ab/output/htmldocs/manpages-3/mount.cifs.8.html
https://linux.die.net/man/8/mount.cifs

uid=arg
sets the uid that will own all files on the mounted filesystem. It may be specified as either a username or a numeric uid. For mounts to servers which do support the CIFS Unix extensions, such as a properly configured Samba server, the server provides the uid, gid and mode so this parameter should not be specified unless the server and client uid and gid numbering differ. If the server and client are in the same domain (e.g. running winbind or nss_ldap) and the server supports the Unix Extensions then the uid and gid can be retrieved from the server (and uid and gid would not have to be specifed on the mount. For servers which do not support the CIFS Unix extensions, the default uid (and gid) returned on lookup of existing files will be the uid (gid) of the person who executed the mount (root, except when mount.cifs is configured setuid for user mounts) unless the "uid=" (gid) mount option is specified. For the uid (gid) of newly created files and directories, ie files created since the last mount of the server share, the expected uid (gid) is cached as long as the inode remains in memory on the client. Also note that permission checks (authorization checks) on accesses to a file occur at the server, but there are cases in which an administrator may want to restrict at the client as well. For those servers which do not report a uid/gid owner (such as Windows), permissions can also be checked at the client, and a crude form of client side permission checking can be enabled by specifying file_mode and dir_mode on the client. Note that the mount.cifs helper must be at version 1.10 or higher to support specifying the uid (or gid) in non-numeric form.

gid=arg
sets the gid that will own all files on the mounted filesystem. It may be specified as either a groupname or a numeric gid. For other considerations see the description of uid above.

file_mode=arg
If the server does not support the CIFS Unix extensions this overrides the default file mode.

dir_mode=arg
If the server does not support the CIFS Unix extensions this overrides the default mode for directories.

rw
mount read-write

noserverino
Client generates inode numbers itself rather than using the actual ones from the server.
See section INODE NUMBERS for more information.

nounix
Disable the CIFS Unix Extensions for this mount. This can be useful in order to turn off multiple settings at once. This includes POSIX acls, POSIX locks, POSIX paths, symlink support and retrieving uids/gids/mode from the server. This can also be useful to work around a bug in a server that supports Unix Extensions.
See section INODE NUMBERS for more information.

Inode Numbers
When Unix Extensions are enabled, we use the actual inode number provided by the server in response to the POSIX calls as an inode number.

When Unix Extensions are disabled and "serverino" mount option is enabled there is no way to get the server inode number. The client typically maps the server-assigned "UniqueID" onto an inode number.

Note that the UniqueID is a different value from the server inode number. The UniqueID value is unique over the scope of the entire server and is often greater than 2 power 32. This value often makes programs that are not compiled with LFS (Large File Support), to trigger a glibc EOVERFLOW error as this won\'t fit in the target structure field. It is strongly recommended to compile your programs with LFS support (i.e. with -D_FILE_OFFSET_BITS=64) to prevent this problem. You can also use "noserverino" mount option to generate inode numbers smaller than 2 power 32 on the client. But you may not be able to detect hardlinks properly

#credentials=/root/.smbcredentials,uid=33,gid=33,rw,nounix,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0

---
### transfer :: tps-hcs-transmogrifier

This script is the last step of the HCS-renaming at the TPS
It consists of the following steps:
- download the export sheet of the TPS-HCS-tmog-download as defined by $docID and $sheetID below --> $TMOG
- build an index of the HCS-folder on the microscope (/shares/nikon/HCS) <-- this accelerates the search and association of the files to their TPS-names   
- permutate through the cells of $TMOG, break the contents into $well and $tpsFN and move the input files to the $outDir using $tpsFn

Prerequisites:
- dos2unix


---
