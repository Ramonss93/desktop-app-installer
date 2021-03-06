#!/bin/bash
##########################################################################
# This script configures qBittorrent daemon to be ready to use.
# @author César Rodríguez González
# @version 1.3, 2016-09-21
# @license MIT
##########################################################################

# Check if the script is being running by a root or sudoer user
if [ "$(id -u)" != "0" ]; then echo ""; echo "This script must be executed by a root or sudoer user"; echo ""; exit 1; fi

# Parameters
if [ -n "$1" ]; then scriptRootFolder="$1"; else scriptRootFolder="`pwd`/../.."; fi
if [ -n "$2" ]; then username="$2"; else username="`whoami`"; fi
if [ -n "$3" ]; then homeFolder="$3"; else homeFolder="$HOME"; fi

# Add common variables
. $scriptRootFolder/common/commonVariables.properties
# Add credentials for authentication
. $credentialFolder/qBittorrent_server.properties
systemctl stop qbittorrent-nox 2>/dev/null

### VARIABLES ############################################################
QBITTORRENT_DAEMON_DOWNLOAD_FOLDER="$homeDownloadFolder/qBittorrent"
QBITTORRENT_DAEMON_TEMP_FOLDER="$homeFolder/.Temporal/qBittorrent"
QBITTORRENT_DAEMON_TORRENT_FOLDER="$homeDownloadFolder/torrents"
QBITTORRENT_DAEMON_WEB_PORT="8081"
QBITTORRENT_DAEMON_TCP_PORT="8999"
QBITTORRENT_DAEMON_FILE="/etc/systemd/system/qbittorrent-nox.service"


### COPY SYSTEMD SERVICE SCRIPT ##########################################
yes | cp -f $scriptRootFolder/etc/systemd.service $QBITTORRENT_DAEMON_FILE


### CREATE QBITTORRENT USER ##############################################
useradd qbtuser -m
# Add system user to qBittorrent group
usermod -a -G qbtuser $username


### CREATE FOLDERS #######################################################
sudo -u $username mkdir -p $QBITTORRENT_DAEMON_DOWNLOAD_FOLDER $QBITTORRENT_DAEMON_TEMP_FOLDER $QBITTORRENT_DAEMON_TORRENT_FOLDER $homeFolder/.config/qBittorrent
sudo -u $username mkdir -p $homeFolder/.local/share/data/qBittorrent


### SETUP APPLICATION CONFIG FILES #######################################
echo "[Preferences]
Connection\PortRangeMin=$QBITTORRENT_DAEMON_TCP_PORT
Downloads\SavePath=$QBITTORRENT_DAEMON_DOWNLOAD_FOLDER
Downloads\TempPathEnabled=true
Downloads\TempPath=$QBITTORRENT_DAEMON_TEMP_FOLDER
Downloads\ScanDirs=$QBITTORRENT_DAEMON_TORRENT_FOLDER
WebUI\Username=$appUsername
WebUI\Password_ha1=@ByteArray(`echo -n $appPassword | md5sum | cut -d ' ' -f 1`)
WebUI\Port=$QBITTORRENT_DAEMON_WEB_PORT
[LegalNotice]
Accepted=true" > $homeFolder/.config/qBittorrent/qBittorrent.conf
chown $username:$username $homeFolder/.config/qBittorrent/qBittorrent.conf


### SETUP SYSTEMD SERVICE ################################################
sed -i "s/=DESCRIPTION.*/=qBittorrent Nox Daemon/g" $QBITTORRENT_DAEMON_FILE
sed -i "s/=man:PACKAGE.*/=man:qbitorrent-nox/g" $QBITTORRENT_DAEMON_FILE
sed -i "s/=SYSTEMD_TYPE.*/=forking/g" $QBITTORRENT_DAEMON_FILE
sed -i "s/=USERNAME.*/=$username/g" $QBITTORRENT_DAEMON_FILE
sed -i "s/=GROUP.*/=$username/g" $QBITTORRENT_DAEMON_FILE
sed -i "s/=COMMAND_AND_PARAMETERS_TO_START_SERVICE.*/=\/usr\/bin\/qbittorrent-nox -d/g" $QBITTORRENT_DAEMON_FILE


### CREATE DIRECT LINKS IN STARTUP MENU ##################################
# Create menu launcher for qbittorrent-daemon's web client.
echo "[Desktop Entry]
Name=qBittorrent Web
Exec=xdg-open http://localhost:$QBITTORRENT_DAEMON_WEB_PORT
Icon=qbittorrent
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=qBittorrent Web" > /usr/share/applications/qbittorrent-nox-cli.desktop
# Create menu launcher to start qbittorrent-daemon.
echo "[Desktop Entry]
Name=qBittorrent daemon start
Exec=gksudo systemctl start qbittorrent-nox
Icon=qbittorrent
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=Start qBittorrent server" > /usr/share/applications/qbittorrent-nox-start.desktop
# Create menu launcher to stop qbittorrent-daemon.
echo "[Desktop Entry]
Name=qBittorrent daemon stop
Exec=gksudo systemctl stop qbittorrent-nox
Icon=qbittorrent
Terminal=false
Type=Application
Categories=Network;P2P;
Comment=Stop qBittorrent server" > /usr/share/applications/qbittorrent-nox-stop.desktop


### OTHERS ###############################################################
# Extract application icons
tar -C /usr/share/ -xvf "$scriptRootFolder/icons/qbittorrent.tar.gz"
# Set ownership of config files and/or folders
chown -R $username:$username $homeFolder/.config/qBittorrent/*
# Set permissions
chmod -R 770 $QBITTORRENT_DAEMON_DOWNLOAD_FOLDER $QBITTORRENT_DAEMON_TEMP_FOLDER $QBITTORRENT_DAEMON_TORRENT_FOLDER
find $homeFolder/.config/qBittorrent/* -type f -print0 2>/dev/null | xargs -0 chmod 660 2>/dev/null
find $homeFolder/.config/qBittorrent/* -type d -print0 2>/dev/null | xargs -0 chmod 770 2>/dev/null
find $homeFolder/.local/share/data/* -type f -print0 2>/dev/null | xargs -0 chmod 660 2>/dev/null
find $homeFolder/.local/share/data -type d -print0 2>/dev/null | xargs -0 chmod 770 2>/dev/null

### PREPARE DAEMON TO START ON SYSTEM BOOT AND START DAEMON NOW ##########
systemctl enable /etc/systemd/system/qbittorrent-nox.service
systemctl daemon-reload
systemctl start qbittorrent-nox
