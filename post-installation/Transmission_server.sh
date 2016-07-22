#!/bin/bash
##########################################################################
# This script configures Transmission daemon to be ready to use.
#
# Author: César Rodríguez González
# Version: 1.3
# Last modified date (dd/mm/yyyy): 22/07/2016
# Licence: MIT
##########################################################################

# Get common variables and check if the script is being running by a root or sudoer user
if [ "$1" != "" ]; then
	scriptRootFolder="$1"
else
	scriptRootFolder=".."
fi
. $scriptRootFolder/common/commonVariables.sh


### VARIABLES ############################################################
TRANSMISSION_DAEMON_USERNAME="$username"
TRANSMISSION_DAEMON_USER_PASSWORD="transmission"
TRANSMISSION_DAEMON_DOWNLOAD_FOLDER="$homeDownloadFolder/Transmission"
TRANSMISSION_DAEMON_TEMP_FOLDER="$homeFolder/.Temporal/Transmission"
TRANSMISSION_DAEMON_TORRENT_FOLDER="$homeDownloadFolder/torrents"
TRANSMISSION_DAEMON_CLIENT_AND_WEB_PORT="9091"
TRANSMISSION_DAEMON_FILE="/etc/systemd/system/transmission-daemon.service"


### CREATE FOLDERS AND SET PERMISSIONS ###################################
sudo -u $username mkdir -p $TRANSMISSION_DAEMON_DOWNLOAD_FOLDER $TRANSMISSION_DAEMON_TEMP_FOLDER $TRANSMISSION_DAEMON_TORRENT_FOLDER
chgrp debian-transmission $TRANSMISSION_DAEMON_DOWNLOAD_FOLDER $TRANSMISSION_DAEMON_TEMP_FOLDER $TRANSMISSION_DAEMON_TORRENT_FOLDER
chmod -R 770 $TRANSMISSION_DAEMON_DOWNLOAD_FOLDER $TRANSMISSION_DAEMON_TEMP_FOLDER $TRANSMISSION_DAEMON_TORRENT_FOLDER


### SETUP APPLICATION CONFIG FILES #######################################
cp /var/lib/transmission-daemon/info/settings.json /var/lib/transmission-daemon/info/settings.json.backup
# Suppress variables to modify from transmission config file
transmissionVariablesToModify="\"download-dir\"\|\"incomplete-dir\"\|\"rpc-password\"\|\"rpc-username\"\|\"rpc-whitelist\"\|\"umask\""
cat /var/lib/transmission-daemon/info/settings.json | grep -v "$transmissionVariablesToModify" | tr -d '}' > /tmp/transmission.json
# Add comma character to last line
lastLine="`awk '/./{line=$0} END{print line}' /tmp/transmission.json`"
sed -i "s/$lastLine/$lastLine,/g" /tmp/transmission.json
# Add modified variables
echo "\"download-dir\": \"$TRANSMISSION_DAEMON_DOWNLOAD_FOLDER\",
\"incomplete-dir\": \"$TRANSMISSION_DAEMON_TEMP_FOLDER\",
\"incomplete-dir-enabled\": true,
\"rpc-password\": \"$TRANSMISSION_DAEMON_USER_PASSWORD\",
\"rpc-username\": \"$TRANSMISSION_DAEMON_USERNAME\",
\"rpc-whitelist\": \"*\",
\"rpc-port\": $TRANSMISSION_DAEMON_CLIENT_AND_WEB_PORT,
\"umask\": 7,
\"watch-dir\": \"$TRANSMISSION_DAEMON_TORRENT_FOLDER\",
\"watch-dir-enabled\": true
}" >> /tmp/transmission.json
# Move temp file to transmission config file
mv /tmp/transmission.json /var/lib/transmission-daemon/info/settings.json


### SETUP SYSTEMD SERVICE ################################################
sed -i "s/=DESCRIPTION.*/=Transmission Daemon/g" $TRANSMISSION_DAEMON_FILE
sed -i "s/=man:PACKAGE.*/=man:transmission-daemon/g" $TRANSMISSION_DAEMON_FILE
sed -i "s/=USERNAME.*/=$username/g" $TRANSMISSION_DAEMON_FILE
sed -i "s/=GROUP.*/=debian-transmission/g" $TRANSMISSION_DAEMON_FILE
sed -i "s/=COMMAND_AND_PARAMETERS_TO_START_SERVICE.*/=\/usr\/bin\/transmission-daemon -f --log-error --config-dir=\/var\/lib\/transmission-daemon\/info/g" $TRANSMISSION_DAEMON_FILE


### CREATE DIRECT LINKS IN STARTUP MENU ##################################
# Create menu launcher for transmission-daemon's web client.
echo "[Desktop Entry]
Name=Transmission Web
Exec=xdg-open http://localhost:$TRANSMISSION_DAEMON_CLIENT_AND_WEB_PORT
Icon=transmission
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=Transmission Web" > /usr/share/applications/transmission-web.desktop
# Create menu launcher to start transmission-daemon.
echo "[Desktop Entry]
Name=Transmission daemon start
Exec=gksudo systemctl start transmission-daemon
Icon=transmission
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=Start Transmission server" > /usr/share/applications/transmission-start.desktop
# Create menu launcher to stop transmission-daemon.
echo "[Desktop Entry]
Name=Transmission daemon stop
Exec=gksudo systemctl stop transmission-daemon
Icon=transmission
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=Stop Transmission server" > /usr/share/applications/transmission-stop.desktop


### OTHERS ###############################################################
# Add user to debian-transmission group
usermod -a -G debian-transmission $username
# Change permission to user transmission-daemon folder
sudo -u $username mkdir -p $homeFolder/.config/transmission-daemon
chmod 770 $homeFolder/.config/transmission-daemon
chown -R $username:debian-transmission /var/lib/transmission-daemon


### PREPARE DAEMON TO START ON SYSTEM BOOT AND START DAEMON NOW ##########
service transmission-daemon stop 2>/dev/null
systemctl enable /etc/systemd/system/transmission-daemon.service
systemctl daemon-reload
systemctl start transmission-daemon

