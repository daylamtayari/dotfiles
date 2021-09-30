#!/bin/bash

# This file setups the system according to whether or not it is a Qubes VM and which OS it is running.
# This scripts needs to be ran by root to fully work otherwise it will only setup the Qubes specific elements.

echo Welcome to tayari\'s dotfiles system setup!

# Check if this system is a Qubes VM and if so apply the necessary changes:
read -e -p 'Please enter `y` if this is running on a Qubes VM and `n` otherwise: ' QUBES
case $QUBES in
	"y")
		export QUBES_GPG_DOMAIN=gpg
		gpg -K
		qubes-gpg-client -K
		printf "\n[gpg]\n\tprogram=qubes-gpg-client-wrapper" >> gitconfig
		printf "\nalias -g gpg=\"qubes-gpg-client-wrapper\"" >> zsh/zshrc
		;;
	"n")
		echo "no for qubes"
		gpg -K
		printf "\n[gpg]\n\tprogram=gpg" >> gitconfig
		;;
	*)
		echo "Invalid response provided - Skipping"
		;;
esac

# Check which distro is running and act accordingly:
echo "Please enter which distro is the current system based off:"
echo "Debian-based: 1; Fedora-based: 2; Arch-based: 3; Red Hat-based: 4; Suse-based: 5."
read -p "Please enter your selection: " DISTRO
case $DISTRO in
	1)
		sudo apt install git
		sudo apt install zsh
		sudo apt install kitty
		sudo apt install firefox
		;;
	2)
		sudo dnf install git
		sudo dnf install zsh
		sudo dnf install kitty
		sudo dnf install firefox
		;;
	3)
		sudo pacman -S git
		sudo pacman -S zsh
		sudo pacman -S kitty
		sudo pacman -S firefox
		;;
	4)
		sudo yum install git
		sudo yum install zsh
		sudo yum install kitty
		sudo yum install firefox
		;;
	5)
		sudo zypper install git
		sudo zypper install zsh
		sudo zypper install kitty
		sudo zypper install firefox
		;;
	*)
		echo "Invalid response provided - Skipping"
		;;
esac

# Set ZSH as the default shell for the system:
case $QUBES in
	"y")
		sudo chsh -s $(which zsh) user
		sudo chsh -s $(which zsh) # Also setting ZSH as the default shell for root.
		;;
	*)
		chsh -s $(which zsh)
		;;
esac
echo ZSH is now the default shell for the system - Please reboot to apply this change.

echo Setup script has finished!
