# nastia-server

This software package provides a collection of automation scripts for running a home server. Originally implemented on the Raspbian Stretch Linux distribution running on a Raspberry Pi 3 B+.

For an in-depth presentation of the project, please visit: www.microfarad.de/pi-server

Unless stated otherwise within the source file headers, please feel free to use and distribute the full contents of this package or parts of it according to the _GNU General Public License v3.0_. 

Nastia is the name of author's daughter.

## The Scripts

Following is the list of available scripts:

* Media stream: 
  * [`photostream`](https://github.com/microfarad-de/nastia-server/blob/master/bin/photostream): 
  Automatically fetches your media files from one or more pre-defined directories, 
  renames them according to their EXIF date and stores them into monthly sub-directories. Detects and eliminates duplicate media files.
  * [`dropbox-photos`](https://github.com/microfarad-de/nastia-server/blob/master/bin/dropbox-photos):
  Automatically downloads photos from a Dropbox folder.
  * [`check-images`](https://github.com/microfarad-de/nastia-server/blob/master/bin/check-images): 
  Checks image files for corruption.
* Automated system backup:
  * [`backup-hdd`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-hdd): 
  Performs an incremental backup of the storage hard-drive while mimicking the Apple Time Machine behavior.
  * [`backup-config`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-config): 
  Creates a backup copy of important configuration files.
  * [`backup-sd`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-sd): 
  Creates a backup image of the Raspberry Pi's SD card to an external hard drive.
  * [`backup-files`](https://github.com/microfarad-de/nastia-server/blob/master/bin/backup-files): 
  Creates a backup copy of a directory to a local or remote SSH location using rsync.
* Dynamic DNS [`dyndns`](https://github.com/microfarad-de/nastia-server/blob/master/bin/dyndns): 
Communicates the server's public IP address to the Dynamic DNS service.
* System diagnostics [`monitor`](https://github.com/microfarad-de/nastia-server/blob/master/bin/monitor): 
Runs extensive system diagnostics every night and sends an automated test report via email.
* Fan control [`fan`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/fan): 
Controls the CPU cooling fan over the Raspberry Pi's GPIO pin. This script runs as a service with `service fan start`.
* UPS control [`ups`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/ups): 
Reads the status of the UPS and ensures a safe shutdown upon power loss (see www.microfarad.de/pi-ups). This script runs as a service with `service ups start`.
* Serial communication over Bluetooth [`bt-daemon`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/bt-daemon): 
Sends text commends over a bluetooth interface and retrieves its answers. This script runs as a service with `service bt-daemon start`.
* Serial console [`serial-cli.py`](https://github.com/microfarad-de/nastia-server/blob/master/lib/serial-cli.py): Serial console based on the pyserial Python module. Connects to a serial device with a specified baud rate and optional timestamps.
* Serial command [`serial-command`](https://github.com/microfarad-de/nastia-server/blob/master/bin/serial-command): Sends a command over a serial port using pyserial and prints the reply. 
* System configuration parameters are stored in the centralized configuration file under 
[`nastia-server.conf`](https://github.com/microfarad-de/nastia-server/blob/master/etc/nastia-server.conf).
* If not stated otherwise, the above scripts are executed unsing cron jobs which are configured under
[`/etc/cron.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/cron.d/nastia-server).

## Dependencies

The following Linux packages need to be installed first:

* `sudo apt-get install rsync imagemagick libimage-exiftool-perl lynx msmtp python`
* `sudo pip install speedtest-cli pyserial ilock --break-system-packages`

## Installation

In order to install this package, checkout contents of the repository into the `/opt/nastia-server` directory on your Linux file system. Also creat symlinks of the cron, logrotate and service configuration files into the respective `etc` sub-directories. 

Finally, edit the configuration file under `/etc/nastia-server.conf` to achieve your desired setup.


