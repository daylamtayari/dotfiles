#!/bin/bash

# This is a script which checks the system for specific dependencies and initializes the system for the setup of the dotfiles.

check_git(){
	if [[ "`git`" != *"These are common Git commands"* ]]; then
		echo 'Error: Git is NOT installed.'
		exit 1
	fi
}

check_gpg(){
	if [[ "`gpg --version`" != *"gpg (GnuPG)"* ]]; then
		echo 'Error: GPG is NOT installed.'
		exit 1
	fi
}


check_git
check_gpg

# Execute the dotbot installation script:
chmod +x setup.sh
chmod +x install
./setup.sh
./install
