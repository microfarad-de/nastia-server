# nastia-server

A set of automation scripts designed to run on a Raspberry Pi with Victron Venus OS.

The scripts in this repository provide supporting functionality for RV automation projects detailed in:

- [microfarad-de/inetbox2mqtt](https://github.com/microfarad-de/inetbox2mqtt)
- [microfarad-de/fridge-controller](https://github.com/microfarad-de/fridge-controller)


Unless otherwise stated in the source file headers, the contents of this package may be used and distributed under the terms of the _GNU General Public License v3.0_.

## Available Scripts

Below is a list of the provided scripts:

* **Automated system backups:**
  * [`backup-hdd`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-hdd) – Performs incremental backups of the storage drive, similar to Apple Time Machine.
  * [`backup-config`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-config) – Creates a backup of important configuration files.
  * [`backup-sd`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/backup-sd) – Creates an image backup of the Raspberry Pi’s SD card to an external drive.
  * [`backup-files`](https://github.com/microfarad-de/nastia-server/blob/master/bin/backup-files) – Copies a directory to a local or remote SSH location using `rsync`.

* **Dynamic DNS:** [`dyndns`](https://github.com/microfarad-de/nastia-server/blob/master/bin/dyndns) – Updates the server’s public IP address with a Dynamic DNS service.

* **System diagnostics:** [`monitor`](https://github.com/microfarad-de/nastia-server/blob/master/bin/monitor) – Runs nightly diagnostics and emails an automated test report.

* **Fan control:** [`fan`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/fan) – Controls the CPU cooling fan using the Raspberry Pi’s GPIO.

* **Bluetooth serial communication:** [`bt-daemon`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/bt-daemon) – Sends text commands over Bluetooth, receives responses, and monitors the connection, restarting the Bluetooth service if needed.

* **GPIO control for non-root users:** [`gpio-daemon`](https://github.com/microfarad-de/nastia-server/blob/master/sbin/gpio-daemon) – Reads GPIO states from temporary files and applies them, while writing selected GPIO states to files.

* **Serial console:** [`serial-cli.py`](https://github.com/microfarad-de/nastia-server/blob/master/lib/serial-cli.py) – A Python-based serial console using PySerial. Connects to a serial device with configurable baud rate and optional timestamps.

* **Serial command sender:** [`serial-command`](https://github.com/microfarad-de/nastia-server/blob/master/bin/serial-command) – Sends commands over a serial port using PySerial and prints the response.

* **Centralized configuration file:** [`nastia-server.conf`](https://github.com/microfarad-de/nastia-server/blob/master/etc/nastia-server.conf) – Stores configuration parameters for all scripts.

* **Cron job configuration:** [`/etc/cron.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/cron.d/nastia-server) – Unless otherwise specified, these scripts are executed using cron jobs configured in this file.

## Dependencies

The following Linux packages must be installed manually (compiled from source if necessary):

* `msmtp`
* `lynx`
* `logrotate`

## Installation

1. Clone this repository into `/opt/nastia-server` on your Raspberry Pi (or other Linux system).

2. Create the following symbolic links:

   ```bash
   ln -s /opt/nastia-server/etc/nastia-server.conf /etc/nastia-server.conf
   ln -s /opt/nastia-server/etc/cron.d/nastia-server /etc/cron.d/nastia-server
   ln -s /opt/nastia-server/etc/logrotate.d/nastia-server /etc/logrotate.d/nastia-server
   ln -s /opt/nastia-server/service/[service_name] /opt/victronenergy/service/[service_name]

   ```
