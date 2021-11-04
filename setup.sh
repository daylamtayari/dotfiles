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

# Check if the user wants to install dependencies and update, and has root access:

## Ask the user if they wish to update:
read -e -p 'Do you which to update the system? (y/n): ' update

## Check which package manager the user is using:
declare -a pms=()
packagemngr='null'
check_pm(){
	if [[ "`which $1`" == "$1 not found" ]]; then
		echo 'false'
	else
		echo 'true'
	fi
}
check_pms(){
	for i in "${pms[@]}"
	do
		if [[ "$(check_pm $i)" == 'true' ]]; then
			packagemngr=$i
			return [n]
		fi
	done
	if [[ "$packagemngr" == 'null' ]]; then
		echo 'No supported package manager found - not updating the system or installing dependencies.'
	fi
}

## Check if the user is able to execute root commands:
is_root='null'
check_root(){
	echo 'To install, you need to be able to authenticate as root - please authenticate as root:'
	if [[ "`sudo -l`" == *"(root)"* ]]; then
		is_root='y'
		echo 'Authentication as sudo successful - installing...'
	else
		is_root='n'
		echo 'Authentication as sudo unsuccessful - skipping install.'
	fi
}

## Function to update the system:
update(){
	echo ''
}

## Function to install dependencies:
install_dependencies(){
	echo ''
}

## Check if the user wants to update and execute accordingly:
case $update in
	"y"|"Y")
		check_pms
		if [ "$packagemngr" == 'null']; then
			return [n]
		fi
		check_root
		if [ "$is_root" == 'y' ]; then
			update
		fi
		;;
	"n"|"N")
		echo 'Updates wont be checked for or installed.'
		;;
	*)
		echo 'Invalid input provided for the update check value - skipping.'
		;;
esac

## Check if user wants to install dependencies and execute the corresponding functions:

read -e -p 'Do you which to install all dependencies of the dotfiles? (y/n): ' depen

case $depen in
	"y"|"Y")
		if [ "$packagemngr" == 'null' ]; then
			return [n]
		fi
		if [ "$is_root" == 'null' ]; then
			check_root
		fi
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


## Install git submodules:
git submodule update --init --recursive


## Set all necessary scripts as executable:
chmod +x ranger/scope.sh


## Install plugin dependencies with git:
### Packer:
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
	~/.local/share/nvim/site/pack/packer/start/packer.nvim


echo Setup script has finished!
