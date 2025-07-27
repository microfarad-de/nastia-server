# nastia-server

This software package provides a collection of automation scripts for running a home server. Originally implemented on the Raspbian Stretch Linux distribution running on a Raspberry Pi 3 B+.

For an in-depth presentation of the project, please visit: www.microfarad.de/pi-server

Unless stated otherwise within the source file headers, please feel free to use and distribute the full contents of this package or parts of it according to the _GNU General Public License v3.0_.

Nastia is the name of author's daughter.

## The Scripts

Following is the list of available scripts:

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
Controls the CPU cooling fan over the Raspberry Pi's GPIO pin.
* Serial communication over Bluetooth [`bt-daemon`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/bt-daemon):
Sends text commends over a bluetooth interface and retrieves its answers. It also monitors the bluetooth connection and restarts the Bluetooth service upon failure.
* GPIO control by non-root users [`gpio-daemon`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/gpio-daemon):
Reads the GPIO pin state from a temporary files and applies it. Write the states of selected GPIO pins to temporary files.
* Serial console [`serial-cli.py`](https://github.com/microfarad-de/nastia-server/blob/master/lib/serial-cli.py): Serial console based on the pyserial Python module. Connects to a serial device with a specified baud rate and optional timestamps.
* Serial command [`serial-command`](https://github.com/microfarad-de/nastia-server/blob/master/bin/serial-command): Sends a command over a serial port using pyserial and prints the reply.
* System configuration parameters are stored in the centralized configuration file under
[`nastia-server.conf`](https://github.com/microfarad-de/nastia-server/blob/master/etc/nastia-server.conf).
* If not stated otherwise, the above scripts are executed unsing cron jobs which are configured under
[`/etc/cron.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/cron.d/nastia-server).

## Dependencies

The following Linux packages need to be manually installed (compiled from source):

* `msmtp`
* `lynx`
* `logrotate`

## Installation

1. In order to install this package, checkout contents of the repository into the `/opt/nastia-server` directory on your Linux file system.

2. Create the following symbolic links:
   - `ln -s /opt/nastia-server/etc/cron.d/nastia-server /etc/cron.d/nastia-server`
   - `ln -s /opt/nastia-server/etc/logrotate.d/nastia-server /etc/logrotate.d/nastia-server`
   - `ln -s /opt/nastia-server/service/<service_name> /opt/victronenergy/service/<service_name>`

3. Customize the configuration file under `/etc/nastia-server.conf`.

4. Customize the cron job configuration file under `/etc/cron.d/nastia-server`.


