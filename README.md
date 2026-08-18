# Installation of the fsdb

We are offering two methods for the installation of the fsdb. Both are guiding you through the installation and give you the opportunity to decide, which part of the installtion you want to run - or not. 

## Automatic installation

The easiest for a stright-forward (de-novo) installation of the fsdb is to clone the repository fsdb-install and run the fsdb-install.sh
```
git clone https://gitlab.com/arnimjenett/fsdb-install/-/tree/main
cd ./fsdb-install
sudo bash fsdb-install.sh
```

## Manual installation

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

## Preparation of the image acquisition systems (IAS)

The image acquisition systems (IAS), serviced by the fsdb need to make the storage location of the images for the fsdb accessible to the fsdb-server. As most IAS run windows as operating system please refer to the microsoft article [File sharing over a network in Windows](https://support.microsoft.com/en-us/windows/file-sharing-over-a-network-in-windows-b58704b2-f53a-4b82-7bc1-80f9994725bf#ID0EBD&ID0EBD) for the details. For security reasons we suggest to share access to this directory exclusivly with an account you create for this task on the IAS (e.g., fsdbrobot).    
The following information of the IAS will be needed during the setup of the fsdb to facilitate the automatic file transfer:
- IP address of the IAS
- (shared) name of the shared directory
- name of the account used to access above shared directory
- password of above acount

### File sharing for the fsdb 

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

## Configuration of the fsdb
The modular architecture of the fsdb allows for modul-specific configuration at any time. Each module comes with its own configuration file, which is managing the functionalities performed by this module. The configuration files are simple flat text files with the following structure:
```
[variable-name] [varialbel-value] 
```
Between [variable-name] and [varialbel-value] the fsdb expects a single white-space. \
The fsdb accepts one comment, lead by '#', per line in the config-files. This can be used to annotate entries, e.g., 
```
[variable-name] [varialbel-value] # [comment]
```
or to temporarily silence an entry without losing it completely, as in 
```
#[variable-name] [varialbel-value]
```
