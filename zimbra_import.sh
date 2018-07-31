#!/bin/bash

# Importing script. Run on destination server {for test - as "su - zimbra"} under SCREEN (!) and after rsyncing data is completed.

if [ "$STY" == "" ];
    then
	echo "Script is running without screen. It may take several hours to work so it's strongly recommended to run it under screen!"
	exit -1
fi

backup_folder="/backups/zmigrate"
zpath="/opt/zimbra/bin/"
cd $backup_folder

echo "Importing all domains..."
USERS=`cat emails.txt`
for i in $USERS;
do
    $zpath/zmprov cd $i zimbraAuthMech zimbra
    echo $i
done


echo "Importing email accounts and setting the old passwords..."
USERPASS="$backup_folder/userpass"
USERDDATA="$backup_folder/userdata"
for i in $USERS
do
    givenName=$(grep givenName: $USERDDATA/$i.txt | cut -d ":" -f2)
    displayName=$(grep displayName: $USERDDATA/$i.txt | cut -d ":" -f2)
    shadowpass=$(cat $USERPASS/$i.shadow)
    $zpath/zmprov ca $i CHANGEme cn "$givenName" displayName "$displayName" givenName "$givenName" 
    $zpath/zmprov ma $i userPassword "$shadowpass"
done


echo "Recreating the distribution lists with members..."
for i in `cat distributinlist.txt`;
do
    $zpath/zmprov cdl $i
    for j in `grep -v '#' distributinlist_members/$i.txt |grep '@'` 
    do
	$zpath/zmprov adlm $i $j
        echo " $j member has been added to list $i"
    done
    echo "$i -- done "
done


echo "Importing aliases for account..."
for i in $USERS
do
    if [ -f "alias/$i.txt" ]; then
        for j in `grep '@' $backup_folder/alias/$i.txt`
        do
	    zmprov aaa $i $j
	    echo "$i has alias $j --- Restored"
        done
    fi
done


echo "Importing filters..."
for file in $backup_folder/filters/*
do
    StrFilter=`cat "$file"`
    Acc=`echo $file | cut -d "/" -f5`
    zmprov ma $Acc zimbraMailSieveScript '$StrFilter'
    echo "Process filter $Acc"
done
echo "All filters have been imported successfully."


echo "Importing signatures..."
# Need to update sig-import module
# /opt/zimbra/bin/zmprov csig test@corp.vinay.com test-signature1 zimbraPrefMailSignatureHTML  '<div>TestSig</div>'
for file in $backup_folder/signatures/*
do
    StrSign=`cat "$file"`
    Acc=`echo $file | cut -d "/" -f5`
    $zpath/zmprov ma $Acc zimbraPrefMailSignatureHTML '$StrSign'
    sigID=`$zpath/zmprov ga $Acc zimbraSignatureId | grep -v "#" | awk '{print $2}'`
    $zpath/zmprov ma $Acc zimbraPrefDefaulltSignatureId $sigID
    $zpath/zmprov ma $Acc zimbraPrefForwardReplySignatureID $sigID
    echo "$Acc --- Restored"
done
echo "All signatures have been imported successfully."



# it would be better to run this under screen because it can take several hours to complete
echo "Importing accounts data - mails, calendar, tasks, contacts, folders etc..."
for i in $USERS;
do
    $zpath/zmmailbox -z -m $i postRestURL "/?fmt=tgz&resolve=skip" $backup_folder/account_data/$i.tgz
    echo "$i -- finished "
done

