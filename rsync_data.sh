#!/bin/bash

# Run this script on destination (new) server as root

old_server="oda-vm-colab.oda.local"
backup_folder="/backups"

rsync -avp -e 'ssh -p 22' root@$old_server:$backup_folder/zmigrate $backup_folder/