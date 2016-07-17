#!/bin/bash
##########################################################################
# This script installs Skype application.
#
# Author: César Rodríguez González
# Version: 1.3
# Last modified date (dd/mm/yyyy): 17/07/2016
# Licence: MIT
##########################################################################

# Get common variables and check if the script is being running by a root or sudoer user
if [ "$1" != "" ]; then
	scriptRootFolder="$1"
else
	scriptRootFolder=".."
fi
. $scriptRootFolder/common/commonVariables.sh

# Commands to download, extract and install a non-repository application.
skypeURL="http://www.skype.com/go/getskype-linux-deb"
wget -O /var/cache/apt/archives/skype.deb $skypeURL 2>&1
gdebi --n /var/cache/apt/archives/skype.deb
apt-get -y install -f