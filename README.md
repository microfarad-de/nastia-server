# nastia-server

This software package provides a collection of automation scripts for running a home server. Originally implemented on the Raspbian Stretch Linux distribution running on a Raspberry Pi 3B+.

For an in-depth presentation of the project, please visit: www.microfarad.de/pi-server

Unless stated otherwise within the source file headers, please feel free to use and distribute the full contents of this package or parts of it according to the _GNU General Public License v3.0_. 

Nastia is the name of author's daughter.

## The Scripts

Following is the list of available scripts:

* Media stream: 
  * [`photostream`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/photostream): 
  automatically fetches your media files from one or more pre-defined directoris, 
  renames them according to the EXIF date and stores them into monthly sub-directories. Detects and eliminates duplicate media files.
  * [`dropbox-photos`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/dropbox-photos):
  automatically downloads photos from a Dropbox folder.
  * [`check-images`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/check-images): 
  checks image files for corruption.
* Automated system backup:
  * [`backup-hdd`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/backup-hdd): 
  performs an incremental backup of the storage hard-drive while mimicking the Apple Time Machine behavior.
  * [`backup-config`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/backup-config): 
  creates a backup copy of important configuration files.
  * [`backup-sd`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/backup-sd): 
  creates a backup image of the Raspberry Pi's SD card to an external hard drive.
* Dynamic DNS [`dyndns`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/dyndns): 
communicates the server's public IP address to the Dynamic DNS service.
* System diagnostics [`monitor`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/bin/monitor): 
runs extensive system diagnostics every night and sends an automated test report via email.
* Fan control [`fan`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/fan): 
controls the CPU cooling fan over the Raspberry Pi's GPIO pin. This script runs as a service with `service fan start`.
* UPS control [`ups`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/sbin/ups): reads the status of the UPS and ensures a safe shutdown upon power loss (see www.microfarad.de/pi-ups). This script runs as a service with `service ups start`.
* System configuration parameters are stored in the centralized configuration file under 
[`nastia-server.conf`](https://github.com/microfarad-de/nastia-server/blob/master/opt/nastia-server/etc/nastia-server.conf).
* If not stated otherwise, the above scripts are executed unsing cron jobs which are configured under
[`/etc/cron.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/cron.d/nastia-server).

## Dependencies

The following Linux packages need to be installed first:

* `apt-get install rsync`
* `apt-get install imagemagick`
* `apt-get install libimage-exiftool-perl`
* `apt-get install lynx`
* `apt-get install python`
  - `pip install speedtest-cli`
  - `pip install pyserial`
  - `pip install ilock`

## Installation

The directory structure of this repository reflects the Linux file system structure relative to its root directory `/`.

In order to install this package, copy the contents of the `opt` directory to your Linux file system. Also copy the cron, logrotate and systemd service configuration files into the respective `etc` sub-directories. 

Finally, create a copy of the configuration file under `/opt/nastia-server/etc/nastia-server.conf` renaming it to `nastia-server.local`, then modify the parameters inside copied file to achieve your desired setup.


