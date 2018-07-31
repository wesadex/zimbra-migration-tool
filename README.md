Toolset to migrate data and settings from one zimbra server to another.

Requrements:

1. Old zimbra server with zimbra working, ssh access, enough free space where $backup_folder is located and enough access rights to create the folder and subfolders inside it.
It's good if root access (or sudo) is accessible.
2. New zimbra server with clean (or configured) zimbra server installed. Privilegies to create $backup_folder and subfolders and also root (or sudo) accessible.


Scripts:

zimbra_export.sh - script for dumping all data into $backup_folder (is set in script) directory.
zimbra_import.sh - script for importing downloaded by zimbra_export.sh data into new zimbra-server.
rsync_data.sh - script which must be running on new server to download (sync) exported data from old zimbra-server.


Used variables:

backup_folder = "/backups/zmigrate" - folder to store data downloaded from old server and synced to new one
zpath = "/opt/zimbra/bin" - path to zimbra binaries, including f.e. zmprov
$STY - system variable contains ID of current screen. Good way to detect whether script is running under screen.


Work order:

1. On old server: run zumbra_export.sh as root. If $backup_folder already exists the script will ask if you want to use the folder with deleting all existing data in it or not.
2. On new server run rsync_data.sh as root (or sudo).
3. On new server run zimbra_import.sh as root (or sudo -u zimbra)


