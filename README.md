# nastia-server

This software package provides a collection of automation scripts for running a home server. Originally implemented on the Raspbian Stretch Linux distribution running on a Raspberry Pi 3B+.

For an in-depth presentation of the project, please visit: www.microfarad.de/pi-server

Unless stated otherwise within the source file headers, please feel free to use and distribute the full contents of this package or parts of it according to the _GNU General Public License v3.0_. 

Nastia is the name of author's daughter.

## The Scripts

Following is the list of available scripts:

* Media stream: 
  * [`bin/photostream`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/photostream): 
  automatically fetches your media files from one or more pre-defined directoris, 
  renames them according to the EXIF date and stores them into monthly sub-directories. Detects and eliminates duplicate media files.
  * [`bin/dropbox-photos`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/dropbox-photos):
  automatically downloads photos from a Dropbox folder.
  * [`bin/check-images`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/check-images): 
  checks image files for corruption.
* Automated system backup:
  * [`bin/backup-hdd`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/backup-hdd): 
  performs an incremental backup of the storage hard-drive while mimicking the Apple Time Machine behavior.
  * [`sbin/backup-config`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/backup-config): 
  creates a backup copy of important configuration files.
  * [`sbin/backup-sd`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/backup-sd): 
  creates a backup image of the Raspberry Pi's SD card to an external hard drive.
* Dynamic DNS [`bin/dyndns`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/dyndns): 
communicates the server's public IP address to the Dynamic DNS service.
* System diagnostics [`bin/monitor`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/monitor): 
runs extensive system diagnostics every night and sends an automated test report via email.
* Fan control [`sbin/fan`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/fan): 
controls the CPU cooling fan over the Raspberry Pi's GPIO pin. This script runs as a service with `service start fan`.
* UPS control [`sbin/ups`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/ups): reads the status of the UPS and ensures a safe shutdown upon power loss (see www.microfarad.de/pi-ups). This script runs as a service with `service start ups`.
* Centralized configuration file [etc/nastia-server.conf](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/etc/nastia-server.conf).

## Installation

The directory structure of this repository reflects the Linux file system structure relative to its root directory `/`.

In order to install this package, please copy the contents of the `opt` directory to your Linux file system; please also copy the cron, logrotate and systemd service configuration files into the respective `etc` sub-directories. Finally, create a copy of the configuration file under `/opt/nastia-server/etc/nastia-server.conf` renaming it to `nastia-server.local`; then modify the parameters inside copied file to achieve your desired setup.

## Dependencies

The following Linux packages need to be installed in order to run this software:

* rsync
* imagemagick
* libimage-exiftool-perl
* lynx
* Python (pip install):
  - speedtest-cli
  - pyserial
  - ilock
  
