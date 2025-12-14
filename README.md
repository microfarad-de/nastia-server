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

* **Cron job configuration:** [`/etc/cron.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/cron.d/nastia-server) – Configures the cron jobs periodically executing some of the above scripts.

* **Logrotate configuration:** [`/etc/logrotate.d/nastia-server`](https://github.com/microfarad-de/nastia-server/blob/master/etc/logrotate.d/nastia-server) - Configures the log rotation policy used by `logrotate`.

* **Service configurations:** `/service/<service_name>` - Configuration files for starting some of the above scripts as a service via the **runit** service supervisor. Services controlled started using the following commands:
   - `svc -u /service/<servoce_name>`: Start a service
   - `svc -d /service/<servoce_name>`: Stops a service
   - `svstat /service/<servoce_name>`: Check the service status

## Dependencies

The following Linux packages must be installed manually:

* `msmtp`
* `lynx`
* `logrotate`

The compiled binaries of the above tools is provided under the `opt` subdirectory. These binaries have been compiled on a Raspberry Pi 3 B+
running Venus OS version `5.10.110-rpi-venus-4`.

The following Python modules must be installed manually with `pip3 install <module>`:

* `pyserial`
* `speedtest-cli`

## Installation

1. Clone this repository into `/data/nastia-server` on your Victron Venus OS system.

2. Create the following symbolic links:

   ```bash
   ln -s /data/nastia-server/opt/logrotate-3.21.0/logrotate /usr/sbin/
   ln -s /data/nastia-server/opt/msmtp-1.8.24/src/msmtp /usr/bin/
   ln -s /data/nastia-server/opt/lynx2.9.0/lynx /usr/bin/
   ln -s /data/nastia-server/etc/nastia-server.conf /etc/
   ln -s /data/nastia-server/etc/cron.d/nastia-server /etc/cron.d/
   ln -s /data/nastia-server/etc/logrotate.d /etc/
   ln -s /data/nastia-server/etc/logrotate.conf /etc/
   ln -s /data/nastia-server/service/* /opt/victronenergy/service/
   ln -s /data/nastia-server/opt/lynx2.9.0/lynx.cfg /usr/local/etc/
   ```

   > **Note:** The system must be rebooted in order for the changes in `/opt/victronenergy/service/` to take effect. Following reboot, the service configurations will appear under the `/service` tmpfs directory.
