#!/bin/bash

# path to backup folder
backup_folder="/backups/zmigrate"
# path to zimbra binary
zpath="/opt/zimbra/bin/"


# if backup folder exists then ask user if he wants to erase all data in this folder and use it to store data. if he doesn't then exit.
if [[ -d "$backup_folder" ]];
    then
	name="NO"
	read -e -i "$name" -p "The folder $backup_folder already exists. Do you still want to store migration data in this folder? All existing data will be deleted. " input
	name="${input:-$name}"
	echo $name
	name=${name^^}
	if [ "$name" == "NO" ] || [ "$name" == "N" ];
	    then 
		echo "Ok. Then backup existing data and run the script again. Good-bye!."
		exit -1;
	    else
		rm -rfv $backup_folder/*
	fi
    else
	mkdir -p $backup_folder
fi


chown -R zimbra.zimbra $backup_folder
cd $backup_folder

#echo "Exporting PATH to zimbra binary..."
#echo "export PATH=$PATH:/opt/zimbra/bin" >> /etc/environment
#source /etc/environment


echo  "Exporting all domains..."
$zpath/zmprov gad > domains.txt


echo "Exporting admin accounts..."
$zpath/zmprov gaaa > admins.txt


echo "Exporting email accounts..."
$zpath/zmprov gad > domains.txt


echo "Exporting all admin accounts..."
$zpath/zmprov gaaa > admins.txt


echo "Exporting  all email account names..."
$zpath/zmprov -l gaa | sort > emails.txt
USERS=`cat emails.txt`
#USERS=`$zpath/zmprov -l gaa | sort`;



echo "Exporting distribution lists..."
$zpath/zmprov gadl > distributinlist.txt


echo "Exporting members of distribution lists..."
mkdir distributinlist_members
for i in `cat distributinlist.txt`
    do
	$zpath/zmprov gdlm $i > "$backup_folder/distributinlist_members/$i.txt"
	echo "$i"
done


echo "Exporting account passwords..."
mkdir userpass
for i in $USERS;
do
    $zpath/zmprov  -l ga $i userPassword | grep userPassword: | awk '{ print $2}' > userpass/$i.shadow
done


echo "Exporting all user names, display names and Given Names..."
mkdir userdata
for i in $USERS;
do
    $zpath/zmprov ga $i  | grep -i Name: > userdata/$i.txt
done


echo "Exporting e-mails, contacts, calendar, tasks etc. It can take a long time..."
mkdir account_data
for email in $USERS;
do
    $zpath/zmmailbox -z -m $email getRestURL '/?fmt=tgz' > account_data/$email.tgz
    echo $email
done


echo "Exporting aliases..."
mkdir alias
for i in $USERS;
do
    zmprov ga  $i | grep zimbraMailAlias |awk '{print $2}' > alias/$i.txt
    echo $i
done
# removing empty aliases
find alias/ -type f -empty | xargs -n1 rm -v



echo "Exporting filters..."
mkdir filters
for ACCOUNT in $USERS;
do
    NAME=`echo $ACCOUNT`;
    filter=`zmprov ga $NAME zimbraMailSieveScript > /tmp/$NAME`
    sed -i -e "1d" /tmp/$NAME
    sed 's/zimbraMailSieveScript: //g' /tmp/$NAME > filters/$NAME
    rm /tmp/$NAME
    echo "$NAME"
done
echo "All filters have been exported successfully."



echo "Exporting signatures..."
mkdir signatures
for ACCOUNT in $USERS;
do
    NAME=`echo $ACCOUNT`;
    sign=`zmprov ga $NAME zimbraPrefMailSignatureHTML > /tmp/sig/$NAME`
    sed -i -e "1d" /tmp/sig/$NAME
    sed 's/zimbraPrefMailSignatureHTML: //g' /tmp/sig/$NAME > signatures/$NAME
    rm /tmp/sig/$NAME
    echo "$NAME"
done
echo "All signatures have been exported successfully."


echo "Exporting signatures... full"
mkdir sig_full
for ACCOUNT in $USERS;
do
    NAME=`echo $ACCOUNT`;
    $zpath/zmprov gsig $NAME > sig_full/$NAME
    echo "$NAME"
done
echo "All full-signatures have been exported successfully."













