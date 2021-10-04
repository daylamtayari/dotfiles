#!/bin/bash

# This file setups the system according to whether or not it is a Qubes VM and which OS it is running.
# This scripts needs to be ran by root to fully work otherwise it will only setup the Qubes specific elements.

echo Welcome to tayari\'s dotfiles system setup!
echo Notice: This tool does not enforce valid inputs. If an input provided is invalid, it will just skip that step.

# Check if the system is a Qubes VM:
qubes='null'
if [[ "`uname -a`" == *"qubes"* ]]; then
	qubes='y'
else
	qubes='n'
fi

# Setup GPG:
read -e -p 'Please enter `y` if GPG has not been configured and `n` otherwise: ' gpg_configured
case $gpg_configured in
	"y"|"Y")
		case $qubes in
			'y')
				export QUBES_GPG_DOMAIN=gpg
				gpg -K
				qubes-gpg-client -K
				printf "\n[gpg]\n\tprogram=qubes-gpg-client-wrapper" >> gitconfig
				printf "\nalias -g gpg=\"qubes-gpg-client-wrapper\"" >> zsh/zshrc
				;;
			'n')
				gpg -K
				printf "\n[gpg]\n\tprogram=gpg" >> gitconfig
				;;
			*)
				echo 'error detecting qubes'
				;;
		esac ;;
	"n"|"N")
		echo 'GPG already configured - skipping.'
		;;
	*)
		echo 'Invalid input provided for GPG configuration value - skipping.'
		;;
esac

# Check if the user wants to install dependencies and has root access:

## Check if the script is being ran as sudo 
read -e -p 'Do you which to install all dependencies of the dotfiles? (y/n): ' depen

## Ask the user which distro they are running:
distro=0
check_distro(){
	echo "Please enter which distro is the current system based off:"
	echo "1: Deian-based --- 2: Fedora-based --- 3: Arch-based --- 4: Red Hat-based --- 5: Suse-based."
	read -p "Please enter your selection: " DISTRO
	if [[ $DISTRO<1 || $DISTRO>5 ]]; then
		echo 'Invalid input provided for distro version - skipping dependency installation.'
	else
		distro=$DISTRO
	fi
}

## Check if the user is able to execute root commands:
is_root='null'
check_root(){
	echo 'To install dependencies, you need to be able to authenticate as root - please authenticate as root:'
	if [[ "`sudo -l`" == *"(root)"* ]]; then
		is_root='y'
		echo 'Authentication as sudo successful - installing dependencies...'
	else
		is_root='n'
		echo 'Authentication as sudo unsuccessful - skipping dependency install.'
	fi
}

## Function to install dependencies:
install_dependencies(){
	echo ''
}

## Check if user wants to install dependencies and execute the corresponding functions:
case $depen in
	"y"|"Y")
		check_distro
		check_root
		if [ "$is_root" == 'y' ]; then
			install_dependencies
		fi
		;;
	"n"|"N")
		echo 'Dependencies will not be installed.'
		;;
	*)
		echo 'Invalid input provided for dependency install value - skipping.'
		;;
esac


# Set ZSH as the default shell of the system:

## Check if ZSH is the default shell:
zsh_def='null'
check_shell(){
	if [[ "${SHELL}" != *"zsh" ]]; then
		zsh_def='n'
	fi
}

## Function to set the ZSH shell depending on whether the system is a Qubes VM:
shell_qubes(){
	case $qubes in
		'y')
			sudo chsh -s $(which zsh) user
			sudo chsh -s $(which zsh) # Also setting ZSH as the default shell for root.
			;;
		'n')
			chsh -s $(which zsh)
			if [[ "$is_root" == "y" ]]; then # Also setting ZSH as the default shell for root.
				sudo chsh -s $(which zsh) 
			fi
			;;
	esac
}

## Check if ZSH is even installed and then execute the appropriate functions:
if ! command -v zsh > /dev/null; then
	echo 'ZSH is not installed - skipping setting ZSH as default shell.'
else
	check_shell
	if [[ "$zsh_def" == 'n' ]]; then 
		shell_qubes
		echo 'ZSH is now the default shell - Please reboot to apply this change.'
	else
		echo 'ZSH is already the default shell.'
	fi
fi


echo Setup script has finished!
