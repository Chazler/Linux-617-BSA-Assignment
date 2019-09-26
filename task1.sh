#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Please run this script with sudo."
	exit 1
fi

read -p "Please specify the source of the csv: " input;

if [[ ! -z "$input" ]]; then
	if  grep -q "http" <<< $input; then
		mkdir /tmp/csv/ 2> /dev/null;
		wget $input -O /tmp/csv/users.csv;
		
		if [[ $? = 0 ]]; then
			csv="/tmp/csv/users.csv";
		else
			echo "Error while downloading csv from source."
			exit 1;
		fi
	else
		if [[ -f $input ]]; then
			csv="$input";
		else
			echo "CSV cannot be found."
			exit 1;
		fi
	fi
else
	echo "Error. Please fill out a valid source";	
	exit 1;
fi


while IFS=";" read -r email DOB group sharedFolder
do
echo "Email= $email"
firstLetter=$(echo "$email" | awk -F "." {'print$1'} | cut -c -1;)
lastName=$(echo "$email" | awk -F "." {'print$2'} | awk -F "@" {'print$1'};)
userName=$(echo "$firstLetter$lastName")
echo "DOB= $DOB"
year=$(echo "$DOB" | awk -F "/" {'print$1'};)
month=$(echo "$DOB" | awk -F "/" {'print$2'};)
plainPassword=$month$year
echo "password= $plainPassword"
echo "Group= $group"
echo "sharedFolder= $sharedFolder";
echo "";
groupArray=( $(echo "$group" | tr "," " " ) );
sharedFolderGroup=$(echo "$sharedFolder" | tail -c +2);

if [[ ! -z "$sharedFolder" && ! -d "$sharedFolder" ]]; then
	echo "Creating shared folder: $sharedFolder";
	sudo mkdir -p "$sharedFolder";

	##Add sharedFolderGroup to groups
	getent group $sharedFolderGroup || sudo groupadd "$sharedFolderGroup";
	chgrp -R $sharedFolderGroup $sharedFolder;
	chmod 770 $sharedFolder;
fi


##Create user
echo "Creating user: $userName";
sudo useradd -d /home/$userName -m -s /bin/bash $userName
if [[ ! $? = 0 ]]; then
	echo "Cannot add user, exiting";
	exit 1;
fi
##Set password
echo "Setting password for $userName"
echo "$userName:$plainPassword" | sudo chpasswd

##Set password age to 0
echo "Setting password change upon login"
sudo chage -d 0 $userName

##Add user to groups
echo "adding user to groups: "
for i in "${groupArray[@]}"
do
	getent group $i || sudo groupadd "$i";
		echo -e "$i "

	sudo usermod -a -G $i $userName;
	##If user is part of sudo group also give him the shutdown alias
	if [[ $i == "sudo" ]]; then
		echo "alias shutdown='sudo shutdown 0'" >> /home/$userName/.bash_aliases;
	fi
done

##Add user sharedFolderGroup group and create softLink to that group
if [[ ! -z $sharedFolder ]]; then
	echo "Adding user to shared folder group and creating a softlink to the shared folder."
	#echo $sharedFolder;
	
	echo "sudo usermod -a -G $sharedFolderGroup $userName";
	ln -s $sharedFolder "/home/$userName/$sharedFolder"
	chown -h $userName:$userName "/home/$userName/$sharedFolder";
fi
echo ""
echo ""
echo "=== Creating New User ==="
echo ""

done < $csv

rm -R /tmp/csv 2> /dev/null
