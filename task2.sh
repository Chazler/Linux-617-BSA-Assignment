#!/bin/bash

if [[ $# = 0 ]]; then
	read -p "Please specify the directory you want to back up: " directory;
else
	directory=$1;
fi

if [[ ! -z $directory && -d $directory ]]; then
	read -p "Name the tarball: " tarballName;
	
	if [[ -f "/tmp/tarball/$tarballName.tar.gz" ]]; then
		echo "Tarball name already exists"
		exit 1;
	fi

	if [[ ! -z $tarballName ]]; then
		if [[ ! -d /tmp/tarball ]]; then
			echo "making temp directory";
			sudo mkdir "/tmp/tarball";	
		fi
		echo "Making tarball";
		cd "/tmp/tarball";
		sudo tar -zcvf "$tarballName.tar.gz" $directory;
 
		if [[ -f "/tmp/tarball/$tarballName.tar.gz" && $? = 0 ]]; then
			read -p "Username: " user;
			read -p "IP adress: " ip;
			read -p "Port number: " port;
			read -p "Target directory: " targetDir;
			if [[ ! -z $user && ! -z $ip && ! -z $port && ! -z $targetDir ]]; then
				targFil="$targetDir/$tarballName.tar.gz";
				sudo scp -P $port "/tmp/tarball/$tarballName.tar.gz" $user@$ip:"$targFile";
			else
				echo "Please fill out all the prompts";
				exit 1;
			fi
		fi
	else
		echo "You have to give the tarball a name";
		exit 1;
	fi
fi
