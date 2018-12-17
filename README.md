# nastia-server

This software package contains a collection of automation tools for running a home server. Originally implemented on the Raspbian Stretch Linux distribution running on a Raspberry Pi 3B+.

Following is the full feature list:

* Media stream: 
  * Automatically fetches your media files from the Dropbox Camera Uploads directory, or any other pre-defined directory, renames them according to the EXIF date and stores them into monthly sub-directories. 
  * Detects and eliminates duplicate media files.
  * Checks image files for corruption.
* Automated system backup:
  * Incremental backup of the storage hard-drive, mimicks the Apple Time Machine behavior.
  * Creates a backup copy of your important configuration files.
  * Creates a backup image of the Raspberry Pi SD card to an external hard drive.
* Communicate the server's public IP address to the Dynamic DNS service
* Run extensive system diagnostics every night and send an automated test report via email
* Control the CPU cooling fan over the Raspberry Pi's GPIO pin

The directory structure of this repository reflects the linux file system structure relative to its root directory _(/)_.

In order to install this package, please copy the contents of the _opt_ directory to your linux file system, also please copy the cron, logrotate and systemd service configuration files into the respective _etc_ sub-directories. Finally, set the parameters within the main configuration file under _/opt/nastia-server/etc/nastia-server.conf_ according to your desired settings.

Feel free to use and distribute the full contents of this package or parts of it according to the _GNU General Public License v3.0_. I hope that you find it useful.
